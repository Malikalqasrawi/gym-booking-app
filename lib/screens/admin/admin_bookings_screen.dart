import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_booking.dart';
import '../../models/booking.dart';
import '../../models/branch.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/money.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import 'admin_booking_detail_screen.dart';

/// Every booking at the gym, upcoming or past, filtered by status and branch.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late Future<List<AdminBooking>> _bookings;
  late Future<List<Branch>> _branches;
  bool _past = false;
  BookingStatus? _status; // null shows every status
  int? _branchId; // null shows every branch

  @override
  void initState() {
    super.initState();
    _branches = context.read<BookingApi>().getBranches();
    _load();
  }

  void _load() {
    _bookings = context.read<AdminApi>().bookings(past: _past, branchId: _branchId, status: _status);
  }

  void _filter(VoidCallback change) {
    setState(() {
      change();
      _load();
    });
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _bookings;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  Future<void> _open(AdminBooking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminBookingDetailScreen(bookingId: booking.id)),
    );
    if (!mounted) return;
    setState(_load); // it may have been cancelled
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings'), actions: const [ThemeToggleButton()]),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Upcoming'), icon: Icon(Icons.upcoming_outlined)),
                ButtonSegment(value: true, label: Text('Past'), icon: Icon(Icons.history)),
              ],
              selected: {_past},
              onSelectionChanged: (values) => _filter(() => _past = values.first),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('All', _status == null, () => _filter(() => _status = null)),
                  for (final status in BookingStatus.values)
                    _chip(status.label, _status == status, () => _filter(() => _status = status)),
                ],
              ),
            ),
            FutureBuilder<List<Branch>>(
              future: _branches,
              builder: (context, snapshot) {
                final branches = snapshot.data ?? const <Branch>[];
                if (branches.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip('All branches', _branchId == null, () => _filter(() => _branchId = null)),
                      for (final branch in branches)
                        _chip(branch.name, _branchId == branch.id, () => _filter(() => _branchId = branch.id)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<AdminBooking>>(
              future: _bookings,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return LoadError(
                    message: error is ApiException ? error.message : 'Could not load the bookings',
                    onRetry: () => setState(_load),
                  );
                }
                final bookings = snapshot.data!;
                if (bookings.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(_past ? 'No past bookings here.' : 'No upcoming bookings here.')),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, booking) in bookings.indexed) ...[
                      // A heading whenever the day changes.
                      if (index == 0 || bookings[index - 1].booking.date != booking.booking.date)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
                          child: Text(booking.booking.dateLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      _BookingRow(booking: booking, onTap: () => _open(booking)),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onSelected) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelected()),
      );
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.onTap});

  final AdminBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = booking.booking;
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text('${b.memberName} with ${b.trainerName}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${b.timeLabel} · ${b.branchName} · ${formatJod(b.price)}', style: muted),
        trailing: BookingStatusChip(status: b.status),
      ),
    );
  }
}
