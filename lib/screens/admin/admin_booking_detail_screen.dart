import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_booking.dart';
import '../../models/booking.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../utils/dates.dart';
import '../../utils/messages.dart';
import '../../utils/money.dart';
import '../../utils/phones.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';

/// One booking with the member's and trainer's contact details, and cancelling it on the gym's side.
class AdminBookingDetailScreen extends StatefulWidget {
  const AdminBookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<AdminBookingDetailScreen> createState() => _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late Future<AdminBooking> _booking;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _booking = context.read<AdminApi>().booking(widget.bookingId);
  }

  Future<void> _cancel(AdminBooking booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelDialog(booking: booking),
    );
    if (reason == null || !mounted) return;

    final api = context.read<AdminApi>();
    setState(() => _busy = true);
    try {
      final updated = await api.cancelBooking(booking.id, reason: reason);
      if (!mounted) return;
      setState(() {
        _booking = Future.value(updated);
      });
      final refund = updated.booking.payment;
      showInfo(context, refund != null && refund.isRefunded
          ? 'Cancelled and refunded ${formatMoney(refund.amount, refund.currency)}. The member and trainer were emailed.'
          : 'Cancelled. The member and trainer were emailed.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking'), actions: const [ThemeToggleButton()]),
      body: FutureBuilder<AdminBooking>(
        future: _booking,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load this booking',
              onRetry: () => setState(_load),
            );
          }
          return _buildDetails(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildDetails(AdminBooking admin) {
    final b = admin.booking;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final payment = b.payment;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Booking #${b.id}', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            BookingStatusChip(status: b.status),
          ],
        ),
        section('Session'),
        _Info(icon: Icons.event, text: '${b.dateLabel} · ${b.timeLabel}'),
        _Info(icon: Icons.place_outlined, text: b.branchName),
        _Info(icon: Icons.payments_outlined, text: '${b.durationMinutes} min · ${formatJod(b.price)}'),
        section('Member'),
        _Info(icon: Icons.person_outline, text: b.memberName),
        _Info(icon: Icons.email_outlined, text: admin.memberEmail),
        if (admin.memberPhone.isNotEmpty) _Info(icon: Icons.phone_outlined, text: Phones.display(admin.memberPhone)),
        section('Trainer'),
        _Info(icon: Icons.sports_gymnastics, text: b.trainerName),
        _Info(icon: Icons.email_outlined, text: admin.trainerEmail),
        if (b.memberNote != null || b.trainerReply != null) section('Messages'),
        if (b.memberNote != null) _Info(icon: Icons.chat_bubble_outline, text: 'Member: ${b.memberNote}'),
        if (b.trainerReply != null) _Info(icon: Icons.reply_outlined, text: 'Trainer: ${b.trainerReply}'),
        if (payment != null) ...[
          section('Payment'),
          _Info(
            icon: payment.isRefunded ? Icons.undo : Icons.receipt_long_outlined,
            text: payment.isRefunded
                ? 'Refunded ${formatMoney(payment.amount, payment.currency)} to ${payment.method}'
                : 'Paid ${formatMoney(payment.amount, payment.currency)} · ${payment.method}'
                    '${payment.paidAt == null ? '' : ' · ${prettyDateTime(payment.paidAt!)}'}',
          ),
        ],
        if (b.status == BookingStatus.cancelled) ...[
          section('Cancellation'),
          _Info(
            icon: Icons.block,
            text: b.cancelledByGym ? 'Cancelled by the gym' : 'Cancelled by the member',
          ),
          if (b.cancellationNote != null) _Info(icon: Icons.notes_outlined, text: b.cancellationNote!),
        ],
        const SizedBox(height: 28),
        if (admin.gymCanCancel)
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _cancel(admin),
            style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
            icon: const Icon(Icons.event_busy_outlined),
            label: const Text('Cancel this session'),
          ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Confirms the cancellation and asks for an optional reason for the member.
class _CancelDialog extends StatefulWidget {
  const _CancelDialog({required this.booking});

  final AdminBooking booking;

  @override
  State<_CancelDialog> createState() => _CancelDialogState();
}

class _CancelDialogState extends State<_CancelDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking.booking;
    final payment = b.payment;
    return AlertDialog(
      title: const Text('Cancel this session?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${b.memberName} with ${b.trainerName}, ${b.dateLabel} at ${b.startTime}.'),
            const SizedBox(height: 8),
            Text(payment != null && b.status == BookingStatus.paid
                ? '${formatMoney(payment.amount, payment.currency)} is refunded in full to ${payment.method}. '
                    'The member and trainer are emailed.'
                : 'Nothing was paid yet. The member and trainer are emailed.'),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLength: 300,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Message to the member (optional)',
                hintText: 'e.g. The trainer is sick today.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44), // not full-width inside a dialog
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Cancel session'),
        ),
      ],
    );
  }
}
