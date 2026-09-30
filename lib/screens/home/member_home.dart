import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/branch.dart';
import '../../services/booking_api.dart';
import '../../utils/dates.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/trainer_avatar.dart';
import '../booking/branch_map_screen.dart';
import '../booking/trainers_screen.dart';
import '../bookings/my_bookings_screen.dart';

/// The member's part of the home screen:
///   1. Your next session (or "nothing booked yet")
///   2. Two quick actions: Book a session / My bookings
///   3. Our branches (swipe sideways, tap one to see its trainers)
///
/// Uses endpoints that already exist: GET /api/bookings/mine and GET /api/branches.
class MemberHome extends StatefulWidget {
  const MemberHome({super.key});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  late Future<List<Booking>> _bookings;
  late Future<List<Branch>> _branches;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<BookingApi>();
    _bookings = api.myBookings();
    _branches = api.getBranches();
  }

  /// Opens a screen, and reloads when the member comes back (they may have booked or cancelled).
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NextSessionCard(
          bookings: _bookings,
          onOpenBookings: () => _open(const MyBookingsScreen()),
          onBook: () => _open(const BranchMapScreen()),
          onRetry: () => setState(_load),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.map_outlined,
                title: 'Book a session',
                subtitle: 'Pick a branch on the map',
                onTap: () => _open(const BranchMapScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.event_note_outlined,
                title: 'My bookings',
                subtitle: 'Upcoming and history',
                onTap: () => _open(const MyBookingsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Our branches', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 128,
          child: FutureBuilder<List<Branch>>(
            future: _branches,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final branches = snapshot.data ?? const <Branch>[];
              if (branches.isEmpty) {
                return const Center(child: Text('Could not load the branches.'));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: branches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) => _BranchTile(
                  branch: branches[i],
                  onTap: () => _open(TrainersScreen(branch: branches[i])),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Your next session" with the trainer, date, time and status. Or a friendly empty state.
class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.bookings,
    required this.onOpenBookings,
    required this.onBook,
    required this.onRetry,
  });

  final Future<List<Booking>> bookings;
  final VoidCallback onOpenBookings;
  final VoidCallback onBook;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<List<Booking>>(
        future: bookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Could not load your sessions'),
              trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
            );
          }

          // Soonest upcoming session first
          final upcoming = snapshot.data!.where((b) => b.isUpcoming).toList()
            ..sort((a, b) => a.date.compareTo(b.date) != 0
                ? a.date.compareTo(b.date)
                : a.startTime.compareTo(b.startTime));

          if (upcoming.isEmpty) {
            return InkWell(
              onTap: onBook,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.event_available_outlined, size: 36, color: scheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No upcoming sessions', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const Text('Tap to book your next workout.'),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            );
          }

          final next = upcoming.first;
          return InkWell(
            onTap: onOpenBookings,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Your next session',
                            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                      ),
                      BookingStatusChip(status: next.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      TrainerAvatar(id: next.trainerId, name: next.trainerName, radius: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(next.trainerName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text('${next.dateLabel} · ${next.timeLabel}'),
                            Text(next.branchName, style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (next.canPay && next.payBy != null) ...[
                    const SizedBox(height: 10),
                    Text('Accepted! Pay before ${prettyDateTime(next.payBy!)} to confirm it.',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                  ],
                  if (upcoming.length > 1) ...[
                    const SizedBox(height: 10),
                    Text('+ ${upcoming.length - 1} more upcoming',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A square-ish button with an icon, a title and a short explanation.
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: scheme.onPrimaryContainer),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
              Text(subtitle, style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}

/// One branch in the sideways list.
class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch, required this.onTap});

  final Branch branch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 200,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.storefront_outlined, color: scheme.primary),
                const SizedBox(height: 8),
                Text(branch.name,
                    style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(branch.address,
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const Spacer(),
                Text('Open ${branch.hours}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
