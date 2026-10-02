import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/booking.dart';
import 'package:gym_booking/models/branch.dart';

Booking booking(int id, String status, String date, {String trainer = 'Sara Haddad'}) => Booking.fromJson({
      'id': id,
      'status': status,
      'trainerId': id,
      'trainerName': trainer,
      'memberId': 9,
      'memberName': 'Malik',
      'branchId': 1,
      'branchName': 'Abdoun Branch',
      'date': date,
      'startTime': '10:00',
      'endTime': '11:00',
      'durationMinutes': 60,
      'price': 20.0,
      'respondBy': '2026-10-01T09:00',
      'canPay': false,
      'canCancel': false,
    });

void main() {
  final now = DateTime(2026, 10, 7, 12, 0);

  test('"Book again" offers the trainer of the last session that took place', () {
    final last = Booking.lastFinishedSession([
      booking(1, 'PAID', '2026-10-01', trainer: 'Sara Haddad'),
      booking(2, 'PAID', '2026-10-05', trainer: 'Lina Nasser'),
      booking(3, 'PAID', '2026-10-09', trainer: 'Omar Saleh'), // hasn't happened yet
      booking(4, 'CANCELLED', '2026-10-06', trainer: 'Dana Khoury'),
      booking(5, 'EXPIRED', '2026-10-06', trainer: 'Faris Odeh'),
    ], now);
    expect(last?.trainerName, 'Lina Nasser');

    expect(Booking.lastFinishedSession([booking(6, 'ACCEPTED', '2026-10-01')], now), isNull,
        reason: 'never paid, so it never took place');
    expect(Booking.lastFinishedSession([], now), isNull, reason: 'new members see no card');
  });

  test('a branch is open between its opening and closing time', () {
    final branch = Branch.fromJson({
      'id': 1,
      'name': 'Abdoun Branch',
      'address': 'Abdoun Circle',
      'city': 'Amman',
      'latitude': 31.95,
      'longitude': 35.88,
      'phone': null,
      'openingTime': '06:00',
      'closingTime': '23:00',
    });

    expect(branch.isOpenAt(DateTime(2026, 10, 7, 6, 0)), isTrue);
    expect(branch.openStatusAt(DateTime(2026, 10, 7, 12, 0)), 'Open now · closes 23:00');
    expect(branch.isOpenAt(DateTime(2026, 10, 7, 23, 0)), isFalse, reason: 'closed at closing time');
    expect(branch.openStatusAt(DateTime(2026, 10, 7, 5, 30)), 'Closed now · opens 06:00');
  });
}
