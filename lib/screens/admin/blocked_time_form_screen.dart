import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../models/blocked_time.dart';
import '../../models/branch.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/dates.dart';
import '../../utils/messages.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';

/// Blocks time for a whole branch or one of its trainers. Shows how many bookings that cancels
/// before saving. Pops with the saved block.
class BlockedTimeFormScreen extends StatefulWidget {
  const BlockedTimeFormScreen({super.key});

  @override
  State<BlockedTimeFormScreen> createState() => _BlockedTimeFormScreenState();
}

class _BlockedTimeFormScreenState extends State<BlockedTimeFormScreen> {
  late Future<(List<Branch>, List<AdminTrainer>)> _data;
  final _reasonController = TextEditingController();

  int? _branchId;
  int? _trainerId; // null blocks the whole branch
  DateTime _startDate = gymToday();
  DateTime _endDate = gymToday();
  bool _allDay = true;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _load() {
    final branches = context.read<BookingApi>().getBranches();
    final trainers = context.read<AdminApi>().trainers();
    _data = (branches, trainers).wait;
  }

  static String _hhmm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool start}) async {
    final today = gymToday();
    final first = start ? today : _startDate;
    final current = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first) ? first : current,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_branchId == null) {
      showError(context, 'Pick a branch.');
      return;
    }
    final draft = BlockedTimeDraft(
      branchId: _trainerId == null ? _branchId : null,
      trainerId: _trainerId,
      startDate: _startDate,
      endDate: _endDate,
      startTime: _allDay ? null : _hhmm(_startTime),
      endTime: _allDay ? null : _hhmm(_endTime),
      reason: _reasonController.text,
    );
    final problem = draft.problem;
    if (problem != null) {
      showError(context, problem);
      return;
    }

    final api = context.read<AdminApi>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final impact = await api.previewBlock(draft);
      if (impact.bookings > 0) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => _ConfirmCancelDialog(impact: impact),
        );
        if (confirmed != true) return;
      }
      navigator.pop(await api.createBlock(draft));
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Block time'), actions: const [ThemeToggleButton()]),
      body: FutureBuilder<(List<Branch>, List<AdminTrainer>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return LoadError(message: 'Could not load the branches and trainers', onRetry: () => setState(_load));
          }
          final (branches, trainers) = snapshot.data!;
          return _buildForm(branches, trainers);
        },
      ),
    );
  }

  Widget _buildForm(List<Branch> branches, List<AdminTrainer> trainers) {
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final atBranch = trainers
        .where((t) => t.branchId == _branchId && t.status != TrainerStatus.deactivated)
        .toList();

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(
          'Members can\'t book blocked times. Sessions already booked inside them are cancelled, '
          'paid ones refunded in full, and the members are emailed.',
          style: muted,
        ),
        section('Branch'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final branch in branches)
              ChoiceChip(
                label: Text(branch.name),
                selected: _branchId == branch.id,
                onSelected: (_) => setState(() {
                  _branchId = branch.id;
                  _trainerId = null;
                }),
              ),
          ],
        ),
        if (_branchId != null) ...[
          section('Who'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                avatar: const Icon(Icons.store_mall_directory_outlined, size: 18),
                label: const Text('Whole branch'),
                selected: _trainerId == null,
                onSelected: (_) => setState(() => _trainerId = null),
              ),
              for (final trainer in atBranch)
                ChoiceChip(
                  label: Text(trainer.fullName),
                  selected: _trainerId == trainer.id,
                  onSelected: (_) => setState(() => _trainerId = trainer.id),
                ),
            ],
          ),
        ],
        section('When'),
        _PickerTile(
          icon: Icons.event,
          label: 'From',
          value: prettyDate(_startDate),
          onTap: () => _pickDate(start: true),
        ),
        _PickerTile(
          icon: Icons.event_available,
          label: 'To',
          value: prettyDate(_endDate),
          onTap: () => _pickDate(start: false),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('All day'),
          subtitle: Text(_allDay ? 'The whole day is blocked' : 'Only these hours, on each of those days'),
          value: _allDay,
          onChanged: (value) => setState(() => _allDay = value),
        ),
        if (!_allDay) ...[
          _PickerTile(
            icon: Icons.schedule,
            label: 'From time',
            value: _hhmm(_startTime),
            onTap: () => _pickTime(start: true),
          ),
          _PickerTile(
            icon: Icons.schedule,
            label: 'To time',
            value: _hhmm(_endTime),
            onTap: () => _pickTime(start: false),
          ),
        ],
        section('Reason'),
        TextField(
          controller: _reasonController,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'e.g. Eid holiday (optional)',
            helperText: 'Shown to members whose sessions are cancelled',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Block time'),
        ),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.icon, required this.label, required this.value, required this.onTap});

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}

/// Shows how many bookings the block cancels and asks the admin to confirm.
class _ConfirmCancelDialog extends StatelessWidget {
  const _ConfirmCancelDialog({required this.impact});

  final BlockImpact impact;

  @override
  Widget build(BuildContext context) {
    final paid = impact.paidBookings;
    return AlertDialog(
      title: Text('Cancel ${impact.bookings} booking(s)?'),
      content: Text(
        '${impact.bookings} booking(s) fall inside this time and will be cancelled.'
        '${paid == 0 ? '' : ' $paid paid one(s) will be refunded in full.'}'
        ' The members and trainers are emailed.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44), // not full-width inside a dialog
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Block and cancel'),
        ),
      ],
    );
  }
}
