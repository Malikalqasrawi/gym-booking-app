import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../models/trainer.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../utils/messages.dart';
import '../../widgets/theme_toggle_button.dart';

/// Edits a trainer's weekly working hours. Pops with the updated trainer once saved.
class ScheduleEditorScreen extends StatefulWidget {
  const ScheduleEditorScreen({super.key, required this.trainer});

  final AdminTrainer trainer;

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _Block {
  _Block(this.start, this.end);

  TimeOfDay start;
  TimeOfDay end;
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  /// The week starts on Sunday in Jordan; Sunday to Thursday is the working week.
  static const _days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
  static const _workweek = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY'];

  late final Map<String, List<_Block>> _blocks = {
    for (final day in _days)
      day: [
        for (final hours in widget.trainer.schedule.where((h) => h.dayOfWeek == day))
          _Block(_parse(hours.startTime), _parse(hours.endTime)),
      ],
  };
  bool _saving = false;

  static TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  static String _dayName(String day) => day[0] + day.substring(1).toLowerCase();

  void _add(String day) {
    final existing = _blocks[day]!;
    // Start where the last block ends, or at 09:00 for an empty day.
    final start = existing.isEmpty ? const TimeOfDay(hour: 9, minute: 0) : existing.last.end;
    final endHour = start.hour + 4;
    final end = endHour > 23 ? const TimeOfDay(hour: 23, minute: 59) : TimeOfDay(hour: endHour, minute: start.minute);
    setState(() => existing.add(_Block(start, end)));
  }

  void _copySundayToWorkweek() {
    final sunday = _blocks['SUNDAY']!;
    setState(() {
      for (final day in _workweek) {
        _blocks[day] = [for (final block in sunday) _Block(block.start, block.end)];
      }
    });
  }

  Future<void> _pick(_Block block, {required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? block.start : block.end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        block.start = picked;
      } else {
        block.end = picked;
      }
    });
  }

  Future<void> _save() async {
    final schedule = [
      for (final day in _days)
        for (final block in _blocks[day]!)
          WorkingHours(dayOfWeek: day, startTime: _format(block.start), endTime: _format(block.end)),
    ];
    final problem = scheduleProblem(schedule);
    if (problem != null) {
      showError(context, problem);
      return;
    }

    final api = context.read<AdminApi>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      navigator.pop(await api.updateSchedule(widget.trainer.id, schedule));
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly schedule'), actions: const [ThemeToggleButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            '${widget.trainer.fullName}\'s working hours. Members can book inside these times, '
            'within the branch\'s opening hours. Existing bookings are kept.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final day in _days)
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(_dayName(day), style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        TextButton.icon(
                          onPressed: () => _add(day),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add hours'),
                        ),
                      ],
                    ),
                    if (_blocks[day]!.isEmpty)
                      Text('Day off', style: TextStyle(color: scheme.onSurfaceVariant)),
                    for (final block in _blocks[day]!)
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => _pick(block, start: true),
                            child: Text(_format(block.start), style: const TextStyle(fontSize: 16)),
                          ),
                          const Text('–'),
                          TextButton(
                            onPressed: () => _pick(block, start: false),
                            child: Text(_format(block.end), style: const TextStyle(fontSize: 16)),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Remove',
                            onPressed: () => setState(() => _blocks[day]!.remove(block)),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    if (day == 'SUNDAY' && _blocks[day]!.isNotEmpty)
                      TextButton(
                        onPressed: _copySundayToWorkweek,
                        child: const Text('Use these hours Monday to Thursday too'),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Save schedule'),
          ),
        ],
      ),
    );
  }
}
