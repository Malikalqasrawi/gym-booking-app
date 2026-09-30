import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/messages.dart';
import '../../utils/money.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import 'checkout_sheet.dart';

/// The member's bookings, in two tabs:
///   Upcoming: waiting for the trainer, awaiting payment, or confirmed (paid), and not over yet
///   History:  everything else (declined, cancelled, expired, finished)
///
///   GET  /api/bookings/mine
///   POST /api/bookings/{id}/cancel
///   Pay → checkout_sheet.dart
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.justBooked});

  /// Set when we arrive straight after sending a request, to show a "Request sent" banner.
  final Booking? justBooked;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late Future<List<Booking>> _future;
  int? _cancellingId; // shows a spinner on that card's Cancel button

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<BookingApi>().myBookings();
  }

  /// Pull-to-refresh: load again and wait until it's done.
  Future<void> _refresh() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {
      // The error is shown by the FutureBuilder
    }
  }

  /// Opens the payment sheet. When it comes back with a booking, it was paid.
  Future<void> _pay(Booking booking) async {
    final paid = await showCheckoutSheet(context, booking);
    if (!mounted) return;
    if (paid != null) {
      showInfo(context, 'Paid! Your session with ${paid.trainerName} is confirmed. The receipt is in your email.');
    }
    setState(_load); // reload either way (e.g. the deadline may have passed meanwhile)
  }

  Future<void> _cancel(Booking booking) async {
    // Paid → the backend refunds it, so tell them where the money goes
    final payment = booking.payment;
    final refund = payment != null && !payment.isRefunded;
    final refundLine = payment != null && refund ? '\n\nYou\'ll get ${formatJod(payment.amount)} back to ${payment.method}.' : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this session?'),
        content: Text('${booking.trainerName}, ${booking.dateLabel} at ${booking.startTime}.$refundLine'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep it')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), // not full-width inside a dialog
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final api = context.read<BookingApi>();
    setState(() => _cancellingId = booking.id);
    try {
      await api.cancelBooking(booking.id);
      if (!mounted) return;
      showInfo(context, refund
          ? 'Session cancelled and refunded. ${booking.trainerName} has been told.'
          : 'Session cancelled. ${booking.trainerName} has been told.');
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    }
    if (!mounted) return;
    setState(() {
      _cancellingId = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My bookings'),
          actions: const [ThemeToggleButton()],
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'History')]),
        ),
        body: FutureBuilder<List<Booking>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return LoadError(
                message: error is ApiException ? error.message : 'Could not load your bookings.',
                onRetry: () => setState(_load),
              );
            }
            final all = snapshot.data!;
            final upcoming = all.where((b) => b.isUpcoming).toList()
              ..sort((a, b) => a.date.compareTo(b.date) != 0
                  ? a.date.compareTo(b.date)
                  : a.startTime.compareTo(b.startTime)); // soonest first
            final history = all.where((b) => !b.isUpcoming).toList(); // newest first (from the backend)

            return TabBarView(
              children: [
                _buildList(upcoming, emptyText: 'No upcoming sessions.\nBook one from the home screen.', showBanner: true),
                _buildList(history, emptyText: 'Nothing here yet.'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<Booking> bookings, {required String emptyText, bool showBanner = false}) {
    final banner = showBanner && widget.justBooked != null ? _SentBanner(booking: widget.justBooked!) : null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        // AlwaysScrollable: pull-to-refresh works even when the list is short or empty
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (banner != null) ...[banner, const SizedBox(height: 12)],
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(emptyText, textAlign: TextAlign.center),
            ),
          for (final booking in bookings) ...[
            BookingCard(
              booking: booking,
              actions: [
                if (booking.canCancel)
                  OutlinedButton(
                    onPressed: _cancellingId == null ? () => _cancel(booking) : null,
                    child: _cancellingId == booking.id
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Cancel'),
                  ),
                if (booking.canPay)
                  FilledButton(
                    onPressed: _cancellingId == null ? () => _pay(booking) : null,
                    child: Text('Pay ${formatJod(booking.price)}'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

/// "Request sent to Sara" (shown once, right after booking)
class _SentBanner extends StatelessWidget {
  const _SentBanner({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(Icons.mark_email_read_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Request sent to ${booking.trainerName}! You\'ll see here when they accept it.',
              style: TextStyle(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
