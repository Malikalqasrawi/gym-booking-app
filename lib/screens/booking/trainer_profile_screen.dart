import 'package:flutter/material.dart';

import '../../models/branch.dart';
import '../../models/trainer.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_avatar.dart';
import 'schedule_screen.dart';

/// A trainer's full profile, shown before booking.
/// Everything here is already in the Trainer we got from the list, so no extra API call is needed.
class TrainerProfileScreen extends StatelessWidget {
  const TrainerProfileScreen({super.key, required this.trainer, required this.branch});

  final Trainer trainer;
  final Branch branch;

  /// Jordan's week starts on Sunday.
  static const _week = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final category = trainer.category;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer'),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // ---- Header ----
          Center(child: TrainerAvatar(id: trainer.id, name: trainer.fullName, radius: 46)),
          const SizedBox(height: 12),
          Text(trainer.fullName,
              textAlign: TextAlign.center, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(trainer.specialty, textAlign: TextAlign.center, style: TextStyle(color: scheme.primary)),
          const SizedBox(height: 4),
          Text(branch.name, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),

          // ---- Three quick facts ----
          Row(
            children: [
              Expanded(child: _Fact(value: '${trainer.yearsOfExperience}', label: 'years')),
              const SizedBox(width: 8),
              Expanded(
                child: _Fact(
                  value: trainer.hourlyRate == null ? '–' : formatJod(trainer.hourlyRate!),
                  label: 'per hour',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: category == null
                    ? const _Fact(value: '–', label: 'category')
                    : _Fact(icon: category.icon, value: category.label, label: 'category'),
              ),
            ],
          ),

          _Section(title: 'About', child: Text(trainer.bio)),

          if (trainer.tags.isNotEmpty)
            _Section(
              title: 'Good for',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tag in trainer.tags) Chip(label: Text(tag), visualDensity: VisualDensity.compact),
                ],
              ),
            ),

          if (trainer.certifications.isNotEmpty)
            _Section(
              title: 'Certifications',
              child: Column(
                children: [
                  for (final certificate in trainer.certifications)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_outlined, size: 18, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(certificate)),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (trainer.languages != null) _Section(title: 'Languages', child: Text(trainer.languages!)),

          _Section(
            title: 'Weekly schedule',
            child: Column(
              children: [
                for (final day in _week) _ScheduleRow(day: day, trainer: trainer),
              ],
            ),
          ),

          _Section(
            title: 'Where',
            child: Text('${branch.name}\n${branch.address}, ${branch.city}\nOpen daily ${branch.hours}'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: trainer.hourlyRate == null
                ? null // not bookable yet
                : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ScheduleScreen(trainer: trainer, branch: branch)),
                    ),
            icon: const Icon(Icons.event_available_outlined),
            label: Text('Book with ${trainer.fullName.split(' ').first}'),
          ),
        ),
      ),
    );
  }
}

/// A small box: big value on top, label underneath.
class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (icon != null) Icon(icon, size: 20, color: scheme.primary),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// A titled block of the profile.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// "Sun   08:00–16:00"  or  "Fri   Off"
class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.day, required this.trainer});

  final String day; // "SUNDAY"
  final Trainer trainer;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final blocks = trainer.schedule.where((block) => block.dayOfWeek == day).toList();
    final hours = blocks.map((block) => '${block.startTime}–${block.endTime}').join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text(shortDayFromBackend(day), style: TextStyle(color: muted))),
          Expanded(
            child: Text(
              blocks.isEmpty ? 'Off' : hours,
              style: blocks.isEmpty ? TextStyle(color: muted) : null,
            ),
          ),
        ],
      ),
    );
  }
}
