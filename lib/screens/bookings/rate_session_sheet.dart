import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../widgets/star_rating.dart';

/// Lets the member rate a finished session. True once the review was sent.
Future<bool> showRateSessionSheet(BuildContext context, Booking booking, {int initialRating = 0}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true, // lets the sheet resize for the keyboard
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) => RateSessionSheet(booking: booking, initialRating: initialRating),
  );
  return sent == true;
}

/// 1 to 5 stars and an optional comment. Reviews are final once sent.
class RateSessionSheet extends StatefulWidget {
  const RateSessionSheet({super.key, required this.booking, this.initialRating = 0});

  final Booking booking;
  final int initialRating; // set when the member tapped a star on the home screen

  @override
  State<RateSessionSheet> createState() => _RateSessionSheetState();
}

class _RateSessionSheetState extends State<RateSessionSheet> {
  final _comment = TextEditingController();
  late int _rating = widget.initialRating;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_rating == 0) {
      setState(() => _error = 'Tap a star to rate the session.');
      return;
    }
    final api = context.read<BookingApi>();
    final navigator = Navigator.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await api.rateSession(widget.booking.id, rating: _rating, comment: _comment.text);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final firstName = widget.booking.trainerName.split(' ').first;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('How was your session with $firstName?',
                textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${widget.booking.dateLabel} · ${widget.booking.timeLabel}',
                textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            StarRatingInput(
              rating: _rating,
              onChanged: (stars) => setState(() {
                _rating = stars;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                hintText: 'What went well? What could be better?',
                border: OutlineInputBorder(),
              ),
            ),
            Text(
              "Reviews can't be changed once sent. $firstName's profile will show your first name and initial.",
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sending ? null : _send,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: _sending
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Send review'),
            ),
          ],
        ),
      ),
    );
  }
}
