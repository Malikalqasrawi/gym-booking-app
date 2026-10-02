import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/review.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/dates.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/trainer_avatar.dart';
import '../trainer/my_reviews_screen.dart';
import 'main_shell.dart';

class TrainerHome extends StatefulWidget {
  const TrainerHome({super.key});

  @override
  State<TrainerHome> createState() => _TrainerHomeState();
}

class _TrainerHomeState extends State<TrainerHome> {
  /// [requests, schedule]. Kept in a field so rebuilds don't refetch.
  late Future<List<List<Booking>>> _data;
  late Future<TrainerReviews> _reviews;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<BookingApi>();
    _data = Future.wait([api.trainerRequests(), api.trainerSchedule()]);
    _reviews = api.myReviews();
  }

  void _openRequests() => TabSwitcher.goTo(context, AppTab.sessions);

  Future<void> _openReviews() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyReviewsScreen()));
    if (!mounted) return;
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return FutureBuilder<List<List<Booking>>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: Text(error is ApiException ? error.message : 'Could not load your sessions'),
            trailing: TextButton(onPressed: () => setState(_load), child: const Text('Retry')),
          );
        }

        final requests = snapshot.data![0];
        final schedule = snapshot.data![1];
        final today = gymToday();
        final todays = schedule.where((b) => b.date == today).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: requests.length,
                    label: 'waiting for you',
                    icon: Icons.inbox_outlined,
                    highlight: requests.isNotEmpty,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: todays.length, label: 'today', icon: Icons.today_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: schedule.length, label: 'upcoming', icon: Icons.event_outlined)),
              ],
            ),
            const SizedBox(height: 20),
            Text("Today's sessions", style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (todays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Nothing booked for today.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            for (final booking in todays) _TodayRow(booking: booking),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openRequests,
              icon: const Icon(Icons.inbox_outlined),
              label: Text(requests.isEmpty
                  ? 'Open requests & schedule'
                  : 'Answer ${requests.length} ${requests.length == 1 ? 'request' : 'requests'}'),
            ),
            const SizedBox(height: 16),
            _ReviewsLink(reviews: _reviews, onTap: _openReviews),
          ],
        );
      },
    );
  }
}

/// The trainer's rating and how many reviews still have no reply; opens their reviews.
class _ReviewsLink extends StatelessWidget {
  const _ReviewsLink({required this.reviews, required this.onTap});

  final Future<TrainerReviews> reviews;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<TrainerReviews>(
      future: reviews,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final String subtitle;
        if (data == null) {
          subtitle = snapshot.hasError ? 'See what members said' : 'Loading…';
        } else if (data.reviewCount == 0) {
          subtitle = 'No reviews yet';
        } else {
          final unanswered = data.reviews.where((review) => review.reply == null).length;
          subtitle = '${data.averageRating!.toStringAsFixed(1)} average · '
              '${data.reviewCount} ${data.reviewCount == 1 ? 'review' : 'reviews'}'
              '${unanswered > 0 ? ' · $unanswered without a reply' : ''}';
        }

        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: onTap,
            leading: const Icon(Icons.star_rounded, color: starColor),
            title: const Text('Your reviews', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon, this.highlight = false});

  final int value;
  final String label;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final fg = highlight ? scheme.onPrimaryContainer : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fg)),
          Text(label, style: TextStyle(fontSize: 12, color: fg)),
        ],
      ),
    );
  }
}

class _TodayRow extends StatelessWidget {
  const _TodayRow({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          TrainerAvatar(id: booking.memberId, name: booking.memberName, radius: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.memberName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${booking.timeLabel} · ${booking.durationMinutes} min'
                  '${booking.status == BookingStatus.accepted ? ' · awaiting payment' : ''}',
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
