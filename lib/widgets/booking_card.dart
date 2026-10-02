import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../utils/dates.dart';
import '../utils/money.dart';
import 'star_rating.dart';

class BookingStatusChip extends StatelessWidget {
  const BookingStatusChip({super.key, required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg, IconData icon) = switch (status) {
      BookingStatus.requested => (scheme.tertiaryContainer, scheme.onTertiaryContainer, Icons.hourglass_top),
      BookingStatus.accepted => (scheme.secondaryContainer, scheme.onSecondaryContainer, Icons.credit_card),
      BookingStatus.paid => dark
          ? (const Color(0xFF1E4620), const Color(0xFFB9F0B8), Icons.check_circle)
          : (const Color(0xFFD4F5D3), const Color(0xFF1B5E20), Icons.check_circle),
      BookingStatus.rejected => (scheme.errorContainer, scheme.onErrorContainer, Icons.cancel),
      BookingStatus.cancelled => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, Icons.block),
      BookingStatus.expired => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant, Icons.timer_off),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// Set [showMember] on trainer screens to show the member instead of the trainer.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.showMember = false,
    this.actions = const [],
  });

  final Booking booking;
  final bool showMember;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final title = showMember ? booking.memberName : booking.trainerName;
    final payment = booking.payment;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 8),
            _Line(icon: Icons.event, text: '${booking.dateLabel} · ${booking.timeLabel}'),
            _Line(icon: Icons.place_outlined, text: booking.branchName),
            _Line(
              icon: Icons.payments_outlined,
              text: '${booking.durationMinutes} min · ${formatJod(booking.price)}',
            ),
            if (booking.memberNote != null) ...[
              const SizedBox(height: 8),
              Text(showMember ? 'Note from ${booking.memberName}:' : 'Your note:', style: muted),
              Text(booking.memberNote!),
            ],
            if (booking.trainerReply != null) ...[
              const SizedBox(height: 8),
              Text(showMember ? 'Your reply:' : '${booking.trainerName} replied:', style: muted),
              Text(booking.trainerReply!),
            ],
            if (booking.status == BookingStatus.cancelled && booking.cancelledByGym) ...[
              const SizedBox(height: 8),
              Text('Cancelled by the gym', style: muted),
              if (booking.cancellationNote != null) Text(booking.cancellationNote!),
            ],
            if (booking.status == BookingStatus.requested && booking.respondBy != null) ...[
              const SizedBox(height: 8),
              Text(
                showMember
                    ? 'Answer before ${prettyDateTime(booking.respondBy!)}'
                    : 'The trainer has until ${prettyDateTime(booking.respondBy!)} to answer.',
                style: muted.copyWith(fontSize: 12),
              ),
            ],
            if (booking.status == BookingStatus.accepted && booking.payBy != null) ...[
              const SizedBox(height: 8),
              Text(
                showMember
                    ? 'Waiting for payment until ${prettyDateTime(booking.payBy!)}'
                    : 'Pay before ${prettyDateTime(booking.payBy!)} to confirm. After that, the time is released.',
                style: TextStyle(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600),
              ),
            ],
            if (payment != null) ...[
              const SizedBox(height: 8),
              _Line(
                icon: payment.isRefunded ? Icons.undo : Icons.receipt_long_outlined,
                text: payment.isRefunded
                    ? 'Refunded ${formatMoney(payment.amount, payment.currency)} to ${payment.method}'
                    : 'Paid ${formatMoney(payment.amount, payment.currency)} · ${payment.method}',
              ),
            ],
            if (booking.status == BookingStatus.paid && !showMember && booking.isUpcoming)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  booking.canCancel && booking.cancelUntil != null
                      ? 'Free cancellation until ${prettyDateTime(booking.cancelUntil!)}'
                      : 'Less than 24 h to go: this session can no longer be cancelled.',
                  style: muted.copyWith(fontSize: 12),
                ),
              ),
            if (booking.rating != null && !showMember) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('You rated ', style: muted),
                  StarRating(rating: booking.rating!),
                ],
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (index, action) in actions.indexed) ...[
                    if (index > 0) const SizedBox(width: 8),
                    // The theme's buttons have infinite minimum width, which a Row can't lay out.
                    Expanded(child: action),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
