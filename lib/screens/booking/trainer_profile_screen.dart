import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../models/review.dart';
import '../../models/trainer.dart';
import '../../services/booking_api.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_avatar.dart';
import 'schedule_screen.dart';
import 'trainer_reviews_screen.dart';

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
          Center(child: TrainerAvatar(id: trainer.id, name: trainer.fullName, radius: 46)),
          const SizedBox(height: 12),
          Text(trainer.fullName,
              textAlign: TextAlign.center, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(trainer.specialty, textAlign: TextAlign.center, style: TextStyle(color: scheme.primary)),
          const SizedBox(height: 4),
          Text(branch.name, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (trainer.reviewCount > 0) ...[
            const SizedBox(height: 6),
            Center(child: RatingSummary(average: trainer.averageRating, count: trainer.reviewCount)),
          ],
          const SizedBox(height: 16),

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

          _ReviewsSection(trainer: trainer),

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
                ? null
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

/// The trainer's latest reviews, with a link to all of them.
class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.trainer});

  final Trainer trainer;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  static const _shown = 3;

  late final Future<TrainerReviews> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = context.read<BookingApi>().trainerReviews(widget.trainer.id);
  }

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);

    return _Section(
      title: 'Reviews',
      child: FutureBuilder<TrainerReviews>(
        future: _reviews,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Text('Could not load the reviews.', style: muted);
          }
          final data = snapshot.data!;
          if (data.reviews.isEmpty) {
            return Text('No reviews yet.', style: muted);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final review in data.reviews.take(_shown)) ...[
                ReviewTile(review: review),
                const SizedBox(height: 10),
              ],
              if (data.reviews.length > _shown)
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TrainerReviewsScreen(trainerName: widget.trainer.fullName, reviews: data),
                  )),
                  child: Text('See all ${data.reviewCount} reviews'),
                ),
            ],
          );
        },
      ),
    );
  }
}

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

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.day, required this.trainer});

  final String day;
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
