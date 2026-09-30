import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/dates.dart';
import '../../widgets/trainer_avatar.dart';
import '../trainer/trainer_requests_screen.dart';

/// The trainer's part of the home screen:
///   1. Three numbers: requests waiting, sessions today, upcoming sessions
///   2. Today's sessions
///   3. A button into the Requests / Schedule screen
///
/// Uses GET /api/trainer/requests and GET /api/trainer/schedule (the lists already exist).
class TrainerHome extends StatefulWidget {
  const TrainerHome({super.key});

  @override
  State<TrainerHome> createState() => _TrainerHomeState();
}

class _TrainerHomeState extends State<TrainerHome> {
  /// Both lists at once: [requests, schedule]. Kept in a field so rebuilding doesn't reload.
  late Future<List<List<Booking>>> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final api = context.read<BookingApi>();
    _data = Future.wait([api.trainerRequests(), api.trainerSchedule()]);
  }

  Future<void> _openRequests() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TrainerRequestsScreen()));
    if (!mounted) return;
    setState(_load); // they may have accepted or declined something
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
          ],
        );
      },
    );
  }
}

/// A number with a label, e.g. "3 / waiting for you".
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon, this.highlight = false});

  final int value;
  final String label;
  final IconData icon;
  final bool highlight; // coloured when there's something to do

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

/// "10:00 – 11:00   Malik   60 min"
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
