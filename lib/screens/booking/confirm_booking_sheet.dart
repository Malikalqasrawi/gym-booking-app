import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/availability.dart';
import '../../models/booking.dart';
import '../../models/branch.dart';
import '../../models/trainer.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../state/session_controller.dart';
import '../../utils/dates.dart';
import '../../utils/money.dart';
import '../home/verify_phone_screen.dart';

/// Sends the booking request. Pops with the created [Booking], or null if dismissed.
class ConfirmBookingSheet extends StatefulWidget {
  const ConfirmBookingSheet({
    super.key,
    required this.trainer,
    required this.branch,
    required this.date,
    required this.slot,
    required this.durationMinutes,
  });

  final Trainer trainer;
  final Branch branch;
  final DateTime date;
  final TimeSlot slot;
  final int durationMinutes;

  @override
  State<ConfirmBookingSheet> createState() => _ConfirmBookingSheetState();
}

class _ConfirmBookingSheetState extends State<ConfirmBookingSheet> {
  final _noteController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final session = context.read<SessionController>();
    // Members confirm their phone number with a code by SMS before their first booking.
    if (session.user?.mustConfirmPhone ?? false) {
      if (!await confirmPhoneNumber(context) || !mounted) return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final booking = await context.read<BookingApi>().requestSession(
            trainerId: widget.trainer.id,
            date: widget.date,
            startTime: widget.slot.start,
            durationMinutes: widget.durationMinutes,
            note: _noteController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(booking);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'PHONE_NOT_VERIFIED') {
        // The app thought it was confirmed, e.g. the number was changed on another device.
        setState(() => _sending = false);
        await session.reloadUser();
        if (mounted) await _send();
        return;
      }
      // Typically SLOT_NOT_AVAILABLE when someone else just took the slot.
      setState(() {
        _sending = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final price = widget.trainer.priceFor(widget.durationMinutes);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Confirm your request', style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _Row(label: 'Trainer', value: widget.trainer.fullName),
            _Row(label: 'Branch', value: widget.branch.name),
            _Row(label: 'Date', value: prettyDate(widget.date)),
            _Row(label: 'Time', value: '${widget.slot.label} (${widget.durationMinutes} min)'),
            if (price != null) _Row(label: 'Price', value: formatJod(price), bold: true),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLength: 300,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note for the trainer (optional)',
                hintText: 'e.g. First session, I have a knee injury',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This is a request: ${widget.trainer.fullName.split(' ').first} has 24 hours to accept it. '
              'You pay after it is accepted.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sending…' : 'Send request'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: TextStyle(color: muted))),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }
}
