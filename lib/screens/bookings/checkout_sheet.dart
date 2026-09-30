import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/payment.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../services/stripe_checkout.dart';
import '../../state/theme_controller.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../../widgets/trainer_avatar.dart';

/// Returns the paid booking, or null if the sheet was dismissed.
Future<Booking?> showCheckoutSheet(BuildContext context, Booking booking) {
  return showModalBottomSheet<Booking>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => CheckoutSheet(booking: booking),
  );
}

/// Starts the payment on the backend and presents Stripe's PaymentSheet. The booking is only
/// treated as paid once the backend has confirmed the payment with Stripe.
class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key, required this.booking});

  final Booking booking;

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  late Future<PaymentStart> _start;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start = context.read<BookingApi>().startPayment(widget.booking.id);
  }

  Future<void> _pay(PaymentStart start) async {
    final api = context.read<BookingApi>();
    final themeMode = context.read<ThemeController>().mode;
    final navigator = Navigator.of(context);

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!start.alreadyPaid) {
        final paid = await StripeCheckout.pay(start, themeMode: themeMode);
        if (!paid) {
          // Sheet dismissed: nothing was charged.
          if (mounted) setState(() => _busy = false);
          return;
        }
      }
      final booking = await api.confirmPayment(start.bookingId);
      if (!mounted) return;
      navigator.pop(booking);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } on PaymentScreenException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: FutureBuilder<PaymentStart>(
        future: _start,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  error is ApiException ? error.message : 'Could not start the payment.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _buildSummary(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildSummary(PaymentStart start) {
    final booking = widget.booking;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final canCancelAfterPaying = start.cancelUntilAfterPaying.isAfter(gymNow());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pay for your session', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        Row(
          children: [
            TrainerAvatar(id: booking.trainerId, name: booking.trainerName, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.trainerName, style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${booking.dateLabel} · ${booking.timeLabel} · ${booking.durationMinutes} min'),
                  Text(booking.branchName, style: muted),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 32),
        Row(
          children: [
            Expanded(child: Text('Total', style: text.titleMedium)),
            Text(formatJod(start.amount), style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),

        _Rule(
          icon: Icons.schedule,
          text: 'Pay before ${prettyDateTime(start.payBy)}. After that, the time is released.',
        ),
        _Rule(
          icon: canCancelAfterPaying ? Icons.event_available_outlined : Icons.warning_amber_rounded,
          color: canCancelAfterPaying ? null : scheme.error,
          text: canCancelAfterPaying
              ? 'Free cancellation (full refund) until ${prettyDateTime(start.cancelUntilAfterPaying)}.'
              : 'The session starts in less than 24 hours, so it can\'t be cancelled after paying.',
        ),
        if (start.publishableKey.startsWith('pk_test_'))
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Test mode: no real money. Use card 4242 4242 4242 4242, any future date and any CVC.',
              style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 13),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: scheme.error)),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : () => _pay(start),
          icon: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.lock_outline),
          label: Text(start.alreadyPaid ? 'Confirm payment' : 'Pay ${formatJod(start.amount)}'),
        ),
        const SizedBox(height: 8),
        Text(
          'Payments are handled by Stripe. Your card details never reach our server.',
          textAlign: TextAlign.center,
          style: muted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colour = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colour),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: colour))),
        ],
      ),
    );
  }
}
