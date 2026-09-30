import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/availability.dart';
import '../../models/booking.dart';
import '../../models/branch.dart';
import '../../models/trainer.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_avatar.dart';
import '../bookings/my_bookings_screen.dart';
import 'confirm_booking_sheet.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.trainer, required this.branch});

  final Trainer trainer;
  final Branch branch;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const _daysAhead = 14; // must match the backend's app.booking.days-ahead
  static const _durations = [30, 45, 60, 90]; // must match the durations the backend accepts

  late final List<DateTime> _dates;
  late DateTime _date;
  int _duration = 60;

  bool _loading = false;
  String? _error;
  Availability? _availability;
  TimeSlot? _slot;

  /// Incremented per request so a slow, older response can't overwrite a newer one.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    final today = gymToday();
    _dates = [for (var i = 0; i < _daysAhead; i++) DateTime(today.year, today.month, today.day + i)];
    _date = _dates.firstWhere(widget.trainer.worksOn, orElse: () => _dates.first);
    _loading = true;
    _fetchSlots();
  }

  void _loadSlots() {
    setState(() {
      _loading = true;
      _error = null;
      _slot = null;
    });
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final myRequest = ++_requestId;
    try {
      final result = await context.read<BookingApi>().getAvailability(
            trainerId: widget.trainer.id,
            date: _date,
            durationMinutes: _duration,
          );
      if (!mounted || myRequest != _requestId) return;
      setState(() => _availability = result);
    } on ApiException catch (e) {
      if (!mounted || myRequest != _requestId) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted && myRequest == _requestId) setState(() => _loading = false);
    }
  }

  void _pickDate(DateTime date) {
    setState(() => _date = date);
    _loadSlots();
  }

  void _pickDuration(int minutes) {
    setState(() => _duration = minutes);
    _loadSlots();
  }

  Future<void> _continue() async {
    final booking = await showModalBottomSheet<Booking>(
      context: context,
      isScrollControlled: true, // lets the sheet resize for the keyboard
      showDragHandle: true,
      builder: (_) => ConfirmBookingSheet(
        trainer: widget.trainer,
        branch: widget.branch,
        date: _date,
        slot: _slot!,
        durationMinutes: _duration,
      ),
    );
    if (!mounted) return;
    if (booking == null) {
      // Dismissed, possibly because the slot was just taken: refresh the times.
      _loadSlots();
      return;
    }
    // Drop the booking flow (map, trainers, schedule) from the back stack.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MyBookingsScreen(justBooked: booking)),
      (route) => route.isFirst,
    );
  }

  String get _priceLabel {
    final price = widget.trainer.priceFor(_duration);
    return price == null ? '' : ' · ${formatJod(price)}';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick a time'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _TrainerHeader(trainer: widget.trainer, branch: widget.branch),
          const SizedBox(height: 20),
          Text('Date', style: text.titleMedium),
          const SizedBox(height: 8),
          _DateStrip(dates: _dates, selected: _date, trainer: widget.trainer, onPick: _pickDate),
          const SizedBox(height: 20),
          Text('Duration', style: text.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final minutes in _durations)
                ButtonSegment<int>(value: minutes, label: Text('$minutes min')),
            ],
            selected: {_duration},
            showSelectedIcon: false,
            onSelectionChanged: (values) => _pickDuration(values.first),
          ),
          const SizedBox(height: 20),
          Text('Available times · ${prettyDate(_date)}', style: text.titleMedium),
          const SizedBox(height: 8),
          _buildSlots(),
        ],
      ),
      bottomNavigationBar: _slot == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${prettyDate(_date)} · ${_slot!.label} · $_duration min$_priceLabel',
                        style: text.titleSmall),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _continue, child: const Text('Continue')),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSlots() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _loadSlots, child: const Text('Try again')),
        ],
      );
    }
    final slots = _availability?.slots ?? const <TimeSlot>[];
    if (slots.isEmpty) {
      final reason = widget.trainer.worksOn(_date)
          ? 'No free times left on this day. Try another day or a shorter session.'
          : '${widget.trainer.fullName.split(' ').first} doesn\'t work on ${weekdayShort(_date)}. Pick another day.';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(reason, style: TextStyle(color: muted)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final slot in slots)
          ChoiceChip(
            label: Text(slot.start),
            tooltip: slot.label,
            selected: _slot?.start == slot.start,
            onSelected: (_) => setState(() => _slot = slot),
          ),
      ],
    );
  }
}

class _TrainerHeader extends StatelessWidget {
  const _TrainerHeader({required this.trainer, required this.branch});

  final Trainer trainer;
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        TrainerAvatar(id: trainer.id, name: trainer.fullName, radius: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trainer.fullName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${trainer.specialty} · ${branch.name}'
                '${trainer.hourlyRate == null ? '' : ' · ${formatJod(trainer.hourlyRate!)}/h'}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.dates, required this.selected, required this.trainer, required this.onPick});

  final List<DateTime> dates;
  final DateTime selected;
  final Trainer trainer;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = dates[i];
          final isSelected = date == selected;
          final works = trainer.worksOn(date);
          final fg = isSelected ? scheme.onPrimary : (works ? scheme.onSurface : scheme.onSurfaceVariant);

          return Opacity(
            opacity: works || isSelected ? 1 : 0.45,
            child: Material(
              color: isSelected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onPick(date),
                child: SizedBox(
                  width: 58,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(i == 0 ? 'Today' : weekdayShort(date), style: TextStyle(fontSize: 12, color: fg)),
                      Text('${date.day}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: fg)),
                      Text(works ? monthShort(date) : 'Off', style: TextStyle(fontSize: 11, color: fg)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
