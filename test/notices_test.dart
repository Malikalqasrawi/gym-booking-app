import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/booking.dart';
import 'package:gym_booking/models/notices.dart';

void main() {
  Booking booking(int id, {String status = 'CANCELLED', String? cancelledBy = 'GYM', String date = '2026-10-07'}) =>
      Booking.fromJson({
        'id': id,
        'status': status,
        'trainerId': 2,
        'trainerName': 'Sara Haddad',
        'memberId': 9,
        'memberName': 'Malik',
        'branchId': 1,
        'branchName': 'Abdoun Branch',
        'date': date,
        'startTime': '10:00',
        'endTime': '11:00',
        'durationMinutes': 60,
        'price': 20.0,
        'cancelledBy': cancelledBy,
        'cancellationNote': 'Air conditioning repair',
      });

  final now = DateTime(2026, 10, 2, 9, 0);

  test('shows sessions the gym cancelled, soonest first', () {
    final notices = gymCancellationNotices([booking(2, date: '2026-10-09'), booking(1)], {}, now);
    expect(notices.map((b) => b.id), [1, 2]);
    expect(notices.first.cancellationNote, 'Air conditioning repair');
  });

  test('skips dismissed ones, past ones, member cancellations and active bookings', () {
    final notices = gymCancellationNotices([
      booking(1),
      booking(2, date: '2026-10-01'),
      booking(3, cancelledBy: 'MEMBER'),
      booking(4, status: 'PAID', cancelledBy: null),
    ], {1}, now);
    expect(notices, isEmpty);
  });
}
