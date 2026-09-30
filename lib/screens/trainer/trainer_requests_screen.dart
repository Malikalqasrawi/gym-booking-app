import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/messages.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';

/// The trainer's screen, in two tabs:
///   Requests: waiting for my answer (Accept / Decline), most urgent first
///   Schedule: sessions I accepted (awaiting payment or paid) that haven't finished yet
///
///   GET  /api/trainer/requests
///   GET  /api/trainer/schedule
///   POST /api/trainer/requests/{id}/accept
///   POST /api/trainer/requests/{id}/reject
class TrainerRequestsScreen extends StatefulWidget {
  const TrainerRequestsScreen({super.key});

  @override
  State<TrainerRequestsScreen> createState() => _TrainerRequestsScreenState();
}

class _TrainerRequestsScreenState extends State<TrainerRequestsScreen> {
  late Future<List<Booking>> _requests;
  late Future<List<Booking>> _schedule;
  int? _busyId; // the request we're answering right now (disables its buttons)

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<BookingApi>();
    _requests = api.trainerRequests();
    _schedule = api.trainerSchedule();
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await Future.wait([_requests, _schedule]);
    } catch (_) {
      // The error is shown by the FutureBuilder
    }
  }

  Future<void> _accept(Booking booking) async {
    await _answer(
      booking,
      (api) => api.acceptRequest(booking.id),
      'Accepted. ${booking.memberName} has been told.',
    );
  }

  Future<void> _decline(Booking booking) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _DeclineDialog(booking: booking),
    );
    if (reason == null || !mounted) return; // closed without declining
    await _answer(
      booking,
      (api) => api.rejectRequest(booking.id, message: reason),
      'Declined. ${booking.memberName} has been told.',
    );
  }

  /// Sends the answer, shows the result, then reloads both tabs.
  Future<void> _answer(Booking booking, Future<Booking> Function(BookingApi api) send, String doneText) async {
    final api = context.read<BookingApi>();
    setState(() => _busyId = booking.id);
    try {
      await send(api);
      if (!mounted) return;
      showInfo(context, doneText);
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message); // e.g. "This request expired because it wasn't answered in time."
    }
    if (!mounted) return;
    setState(() {
      _busyId = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My sessions'),
          actions: const [ThemeToggleButton()],
          bottom: const TabBar(tabs: [Tab(text: 'Requests'), Tab(text: 'Schedule')]),
        ),
        body: TabBarView(
          children: [
            _BookingList(
              future: _requests,
              onRefresh: _refresh,
              onRetry: () => setState(_load),
              emptyText: 'No requests waiting.\nNew ones will show up here.',
              actionsFor: (booking) => [
                OutlinedButton(
                  onPressed: _busyId == null ? () => _decline(booking) : null,
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: _busyId == null ? () => _accept(booking) : null,
                  child: _busyId == booking.id
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Accept'),
                ),
              ],
            ),
            _BookingList(
              future: _schedule,
              onRefresh: _refresh,
              onRetry: () => setState(_load),
              emptyText: 'No upcoming sessions yet.',
              actionsFor: (_) => const [],
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab: loading / error / empty / the list of cards.
class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.future,
    required this.onRefresh,
    required this.onRetry,
    required this.emptyText,
    required this.actionsFor,
  });

  final Future<List<Booking>> future;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final String emptyText;
  final List<Widget> Function(Booking booking) actionsFor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return LoadError(
            message: error is ApiException ? error.message : 'Could not load your sessions.',
            onRetry: onRetry,
          );
        }
        final bookings = snapshot.data!;
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (bookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Text(emptyText, textAlign: TextAlign.center),
                ),
              for (final booking in bookings) ...[
                BookingCard(booking: booking, showMember: true, actions: actionsFor(booking)),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Asks for an optional reason. Closes with the reason ('' if none), or null if cancelled.
class _DeclineDialog extends StatefulWidget {
  const _DeclineDialog({required this.booking});

  final Booking booking;

  @override
  State<_DeclineDialog> createState() => _DeclineDialogState();
}

class _DeclineDialogState extends State<_DeclineDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline this request?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.booking.memberName}, ${widget.booking.dateLabel} at ${widget.booking.startTime}.'),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLength: 300,
            maxLines: 3,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: "e.g. I'm away that day",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reasonController.text),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), // not full-width inside a dialog
          child: const Text('Decline'),
        ),
      ],
    );
  }
}
