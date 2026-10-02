import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../utils/dates.dart';
import '../../utils/messages.dart';
import '../../utils/money.dart';
import '../../utils/phones.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_avatar.dart';
import '../../widgets/trainer_status_chip.dart';
import 'schedule_editor_screen.dart';
import 'trainer_form_screen.dart';

class AdminTrainerDetailScreen extends StatefulWidget {
  const AdminTrainerDetailScreen({super.key, required this.trainerId});

  final int trainerId;

  @override
  State<AdminTrainerDetailScreen> createState() => _AdminTrainerDetailScreenState();
}

class _AdminTrainerDetailScreenState extends State<AdminTrainerDetailScreen> {
  late Future<AdminTrainer> _trainer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _trainer = context.read<AdminApi>().trainer(widget.trainerId);
  }

  void _show(AdminTrainer updated) {
    setState(() {
      _trainer = Future.value(updated);
    });
  }

  Future<void> _edit(AdminTrainer trainer) async {
    final updated = await Navigator.of(context).push<AdminTrainer>(
      MaterialPageRoute(builder: (_) => TrainerFormScreen(trainer: trainer)),
    );
    if (!mounted || updated == null) return;
    _show(updated);
    showInfo(context, 'Saved.');
  }

  Future<void> _editSchedule(AdminTrainer trainer) async {
    final updated = await Navigator.of(context).push<AdminTrainer>(
      MaterialPageRoute(builder: (_) => ScheduleEditorScreen(trainer: trainer)),
    );
    if (!mounted || updated == null) return;
    _show(updated);
    showInfo(context, 'Schedule saved.');
  }

  /// Runs an admin action, shows the returned trainer and a confirmation.
  Future<void> _run(Future<AdminTrainer> Function(AdminApi api) action, String doneText) async {
    final api = context.read<AdminApi>();
    setState(() => _busy = true);
    try {
      final updated = await action(api);
      if (!mounted) return;
      _show(updated);
      showInfo(context, doneText);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deactivate(AdminTrainer trainer) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _DeactivateDialog(trainer: trainer),
    );
    if (reason == null || !mounted) return;

    final api = context.read<AdminApi>();
    setState(() => _busy = true);
    try {
      final result = await api.deactivate(trainer.id, reason: reason);
      if (!mounted) return;
      _show(result.trainer);
      showInfo(context, switch (result.cancelledBookings) {
        0 => '${trainer.fullName} was deactivated.',
        _ => '${trainer.fullName} was deactivated. ${result.cancelledBookings} booking(s) cancelled, '
            '${result.refundedBookings} refunded.',
      });
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainer'), actions: const [ThemeToggleButton()]),
      body: FutureBuilder<AdminTrainer>(
        future: _trainer,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load this trainer',
              onRetry: () => setState(_load),
            );
          }
          return _buildDetails(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDetails(AdminTrainer trainer) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            TrainerAvatar(id: trainer.id, name: trainer.fullName, radius: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trainer.fullName, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text(trainer.specialty, style: muted),
                  const SizedBox(height: 6),
                  TrainerStatusChip(status: trainer.status),
                ],
              ),
            ),
          ],
        ),
        if (trainer.status == TrainerStatus.invited && trainer.inviteExpiresAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Waiting for the trainer to accept the invite. '
              'The code expires ${prettyDateTime(trainer.inviteExpiresAt!)}.',
              style: muted,
            ),
          ),
        const Divider(height: 32),
        _Info(icon: Icons.email_outlined, text: trainer.email),
        _Info(icon: Icons.phone_outlined, text: Phones.display(trainer.phone)),
        _Info(icon: Icons.location_on_outlined, text: trainer.branchName ?? 'No branch'),
        _Info(icon: Icons.category_outlined, text: trainer.category?.label ?? 'No category'),
        _Info(
          icon: Icons.payments_outlined,
          text: trainer.hourlyRate == null ? 'No rate' : '${formatJod(trainer.hourlyRate!)} per hour',
        ),
        _Info(icon: Icons.workspace_premium_outlined, text: '${trainer.yearsOfExperience} years of experience'),
        if (trainer.languages.isNotEmpty) _Info(icon: Icons.translate, text: trainer.languages),
        _Info(icon: Icons.event_outlined, text: '${trainer.upcomingBookings} upcoming booking(s)'),
        if (trainer.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final tag in trainer.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact)],
          ),
        ],
        if (trainer.bio.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(trainer.bio),
        ],
        const Divider(height: 32),
        Text('Weekly schedule', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (trainer.schedule.isEmpty) Text('No working hours yet, so members see no free times.', style: muted),
        for (final block in trainer.schedule)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(width: 48, child: Text(shortDayFromBackend(block.dayOfWeek))),
                Text('${block.startTime} – ${block.endTime}'),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (trainer.status != TrainerStatus.deactivated) ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _edit(trainer),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit details'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _editSchedule(trainer),
            icon: const Icon(Icons.schedule),
            label: const Text('Edit schedule'),
          ),
          const SizedBox(height: 10),
        ],
        if (trainer.status == TrainerStatus.invited) ...[
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => _run((api) => api.resendInvite(trainer.id), 'New invite sent to ${trainer.email}.'),
            icon: const Icon(Icons.forward_to_inbox_outlined),
            label: const Text('Resend invite'),
          ),
          const SizedBox(height: 10),
        ],
        if (trainer.status == TrainerStatus.deactivated)
          FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run((api) => api.reactivate(trainer.id), '${trainer.fullName} is active again.'),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Reactivate'),
          )
        else
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _deactivate(trainer),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Deactivate'),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Confirms deactivation and asks for an optional reason, which members see if their booking is cancelled.
class _DeactivateDialog extends StatefulWidget {
  const _DeactivateDialog({required this.trainer});

  final AdminTrainer trainer;

  @override
  State<_DeactivateDialog> createState() => _DeactivateDialogState();
}

class _DeactivateDialogState extends State<_DeactivateDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = widget.trainer.upcomingBookings;
    return AlertDialog(
      title: Text('Deactivate ${widget.trainer.fullName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(upcoming == 0
              ? 'They will be hidden from members and won\'t be able to log in.'
              : 'They will be hidden from members and won\'t be able to log in. '
                  'Their $upcoming upcoming booking(s) will be cancelled, and paid ones refunded in full.'),
          if (upcoming > 0) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLength: 300,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message to members (optional)',
                hintText: 'e.g. Your trainer has left the gym.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44), // not full-width inside a dialog
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Deactivate'),
        ),
      ],
    );
  }
}
