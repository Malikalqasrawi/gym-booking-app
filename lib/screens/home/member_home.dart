import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/branch.dart';
import '../../models/notices.dart';
import '../../models/training_category.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../services/notice_storage.dart';
import '../../utils/dates.dart';
import '../../utils/messages.dart';
import '../../utils/money.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/trainer_avatar.dart';
import '../booking/category_trainers_screen.dart';
import '../booking/trainer_profile_screen.dart';
import '../booking/trainers_screen.dart';
import '../bookings/rate_session_sheet.dart';
import 'main_shell.dart';

class MemberHome extends StatefulWidget {
  const MemberHome({super.key});

  @override
  State<MemberHome> createState() => _MemberHomeState();
}

class _MemberHomeState extends State<MemberHome> {
  late Future<List<Booking>> _bookings;
  late Future<List<Branch>> _branches;
  Set<int>? _dismissed; // null until read from storage, so notices don't flash
  Set<int>? _skippedRatings;

  @override
  void initState() {
    super.initState();
    _load();
    NoticeStorage.dismissed().then((ids) {
      if (mounted) setState(() => _dismissed = ids);
    });
    NoticeStorage.skippedRatings().then((ids) {
      if (mounted) setState(() => _skippedRatings = ids);
    });
  }

  void _dismiss(int bookingId) {
    setState(() => _dismissed = {...?_dismissed, bookingId});
    NoticeStorage.dismiss(bookingId);
  }

  void _skipRating(int bookingId) {
    setState(() => _skippedRatings = {...?_skippedRatings, bookingId});
    NoticeStorage.skipRating(bookingId);
  }

  Future<void> _rate(Booking booking, int stars) async {
    final sent = await showRateSessionSheet(context, booking, initialRating: stars);
    if (!sent || !mounted) return;
    showInfo(context, 'Thanks for your review!');
    setState(_load);
  }

  void _load() {
    final api = context.read<BookingApi>();
    _bookings = api.myBookings();
    _branches = api.getBranches();
  }

  /// Pushes [screen] and reloads afterwards, since the member may have booked or cancelled.
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
        _GymCancellationNotices(
          bookings: _bookings,
          dismissed: _dismissed,
          onDismiss: _dismiss,
          onBookAgain: () => TabSwitcher.goTo(context, AppTab.book),
        ),
        _NextSessionCard(
          bookings: _bookings,
          onOpenBookings: () => TabSwitcher.goTo(context, AppTab.bookings),
          onBook: () => TabSwitcher.goTo(context, AppTab.book),
          onRetry: () => setState(_load),
        ),
        _RateSessionCard(bookings: _bookings, skipped: _skippedRatings, onRate: _rate, onSkip: _skipRating),
        _BookAgainCard(bookings: _bookings, branches: _branches, onOpen: _open),
        const SizedBox(height: 24),
        Text('Train by category', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _CategoryGrid(onTap: (category) => _open(CategoryTrainersScreen(category: category))),
        const SizedBox(height: 24),
        Text('Our branches', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        FutureBuilder<List<Branch>>(
          future: _branches,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final branches = snapshot.data ?? const <Branch>[];
            if (branches.isEmpty) {
              return const Text('Could not load the branches.');
            }
            final now = gymNow();
            return Column(
              children: [
                for (final branch in branches) ...[
                  _BranchTile(
                    branch: branch,
                    isOpen: branch.isOpenAt(now),
                    status: branch.openStatusAt(now),
                    onTap: () => _open(TrainersScreen(branch: branch)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Asks the member to rate their latest finished session. Tapping a star opens the review sheet
/// with that many stars picked.
class _RateSessionCard extends StatelessWidget {
  const _RateSessionCard({required this.bookings, required this.skipped, required this.onRate, required this.onSkip});

  final Future<List<Booking>> bookings;
  final Set<int>? skipped;
  final void Function(Booking booking, int stars) onRate;
  final ValueChanged<int> onSkip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return FutureBuilder<List<Booking>>(
      future: bookings,
      builder: (context, snapshot) {
        final seen = skipped;
        if (!snapshot.hasData || seen == null) return const SizedBox.shrink();
        final booking = Booking.nextToRate(snapshot.data!, seen);
        if (booking == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TrainerAvatar(id: booking.trainerId, name: booking.trainerName, radius: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How was your session with ${booking.trainerName.split(' ').first}?',
                              style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${booking.dateLabel} · ${booking.branchName}',
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    TextButton(onPressed: () => onSkip(booking.id), child: const Text('Not now')),
                  ],
                ),
                Row(
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                        onPressed: () => onRate(booking, star),
                        icon: const Icon(Icons.star_outline_rounded, color: starColor, size: 32),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The trainer of the member's last finished session, to book them again in one tap. Hidden
/// until the member has had a session.
class _BookAgainCard extends StatefulWidget {
  const _BookAgainCard({required this.bookings, required this.branches, required this.onOpen});

  final Future<List<Booking>> bookings;
  final Future<List<Branch>> branches;
  final Future<void> Function(Widget screen) onOpen;

  @override
  State<_BookAgainCard> createState() => _BookAgainCardState();
}

class _BookAgainCardState extends State<_BookAgainCard> {
  bool _opening = false;

  /// Loads the trainer's current profile (their branch or rates may have changed) and opens it.
  Future<void> _open(Booking last) async {
    final api = context.read<BookingApi>();
    setState(() => _opening = true);
    try {
      final trainer = await api.getTrainer(last.trainerId);
      final branches = await widget.branches;
      final branch = branches.where((b) => b.id == trainer.branchId).firstOrNull;
      if (branch == null || !mounted) return;
      await widget.onOpen(TrainerProfileScreen(trainer: trainer, branch: branch));
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return FutureBuilder<List<Booking>>(
      future: widget.bookings,
      builder: (context, snapshot) {
        final last = Booking.lastFinishedSession(snapshot.data ?? const [], gymNow());
        if (last == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Material(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _opening ? null : () => _open(last),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    TrainerAvatar(id: last.trainerId, name: last.trainerName, radius: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Book again', style: text.labelMedium?.copyWith(color: scheme.onPrimaryContainer)),
                          Text(last.trainerName,
                              style: text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                          Text('Last session ${last.dateLabel} · ${last.branchName}',
                              style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
                        ],
                      ),
                    ),
                    _opening
                        ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One tile per training category, plus "All trainers"; each lists trainers from every branch.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onTap});

  final ValueChanged<TrainingCategory?> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget tile(IconData icon, String label, TrainingCategory? category) => Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(category),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
        );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // the home screen scrolls, not the grid
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3,
      children: [
        for (final category in TrainingCategory.values) tile(category.icon, category.label, category),
        tile(Icons.groups_outlined, 'All trainers', null),
      ],
    );
  }
}

/// One card per session the gym cancelled, until the member taps "Got it".
class _GymCancellationNotices extends StatelessWidget {
  const _GymCancellationNotices({
    required this.bookings,
    required this.dismissed,
    required this.onDismiss,
    required this.onBookAgain,
  });

  final Future<List<Booking>> bookings;
  final Set<int>? dismissed;
  final ValueChanged<int> onDismiss;
  final VoidCallback onBookAgain;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: bookings,
      builder: (context, snapshot) {
        final seen = dismissed;
        if (!snapshot.hasData || seen == null) return const SizedBox.shrink();
        final notices = gymCancellationNotices(snapshot.data!, seen, gymNow());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final booking in notices)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _GymCancellationCard(
                  booking: booking,
                  onDismiss: () => onDismiss(booking.id),
                  onBookAgain: onBookAgain,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GymCancellationCard extends StatelessWidget {
  const _GymCancellationCard({required this.booking, required this.onDismiss, required this.onBookAgain});

  final Booking booking;
  final VoidCallback onDismiss;
  final VoidCallback onBookAgain;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fg = scheme.onErrorContainer;
    final payment = booking.payment;

    return Card(
      elevation: 0,
      color: scheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_busy, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('The gym cancelled your session',
                      style: text.titleMedium?.copyWith(color: fg, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${booking.trainerName} · ${booking.dateLabel} at ${booking.startTime}', style: TextStyle(color: fg)),
            if (booking.cancellationNote != null)
              Text('Reason: ${booking.cancellationNote}', style: TextStyle(color: fg)),
            Text(
              payment != null && payment.isRefunded
                  ? 'You were refunded ${formatMoney(payment.amount, payment.currency)} to ${payment.method}.'
                  : 'Nothing was charged.',
              style: TextStyle(color: fg),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onBookAgain,
                  style: TextButton.styleFrom(foregroundColor: fg),
                  child: const Text('Book another time'),
                ),
                TextButton(
                  onPressed: onDismiss,
                  style: TextButton.styleFrom(foregroundColor: fg),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
            final error = snapshot.error;
            return ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: Text(error is ApiException ? error.message : 'Could not load your sessions'),
              trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
            );
          }

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

/// A branch with whether it is open right now; opens its trainers.
class _BranchTile extends StatelessWidget {
  const _BranchTile({required this.branch, required this.isOpen, required this.status, required this.onTap});

  final Branch branch;
  final bool isOpen;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final openColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: scheme.primaryContainer,
                child: Icon(Icons.storefront_outlined, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(branch.address,
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: isOpen ? openColor : scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(status,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isOpen ? openColor : scheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
