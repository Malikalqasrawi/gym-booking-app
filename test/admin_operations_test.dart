import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/admin_booking.dart';
import 'package:gym_booking/models/availability.dart';
import 'package:gym_booking/models/blocked_time.dart';
import 'package:gym_booking/models/booking.dart';
import 'package:gym_booking/models/branch.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('reads an admin booking: booking fields and contact details in one object', () {
    final admin = AdminBooking.fromJson({
      'id': 58,
      'status': 'PAID',
      'trainerId': 2,
      'trainerName': 'Sara Haddad',
      'memberId': 9,
      'memberName': 'Malik',
      'branchId': 1,
      'branchName': 'Abdoun Branch',
      'date': '2026-10-07',
      'startTime': '10:00',
      'endTime': '11:00',
      'durationMinutes': 60,
      'price': 20.0,
      'canPay': false,
      'canCancel': false,
      'memberEmail': 'malik@test.com',
      'memberPhone': '0791234567',
      'trainerEmail': 'sara.trainer@gym.com',
      'gymCanCancel': true,
    });
    expect(admin.id, 58);
    expect(admin.booking.status, BookingStatus.paid);
    expect(admin.booking.canCancel, isFalse, reason: 'the member is past the 24 h limit');
    expect(admin.gymCanCancel, isTrue, reason: 'the gym can still cancel');
    expect(admin.memberPhone, '0791234567');
  });

  test('reads blocked times and labels them', () {
    final branch = BlockedTime.fromJson({
      'id': 4,
      'branchId': 3,
      'branchName': 'Sweifieh Branch',
      'trainerId': null,
      'trainerName': null,
      'startDate': '2026-10-05',
      'endDate': '2026-10-07',
      'startTime': null,
      'endTime': null,
      'allDay': true,
      'reason': 'Eid holiday',
    });
    expect(branch.isBranch, isTrue);
    expect(branch.targetName, 'Sweifieh Branch');
    expect(branch.whenLabel, 'Mon 5 Oct – Wed 7 Oct, all day');

    final trainer = BlockedTime.fromJson({
      'id': 5,
      'trainerId': 2,
      'trainerName': 'Sara Haddad',
      'startDate': '2026-10-05',
      'endDate': '2026-10-05',
      'startTime': '14:00',
      'endTime': '17:00',
      'allDay': false,
    });
    expect(trainer.isBranch, isFalse);
    expect(trainer.whenLabel, 'Mon 5 Oct, 14:00 – 17:00');
    expect(trainer.reason, isNull);
  });

  test('blocked time draft: JSON for the backend and the same checks', () {
    final wholeDays = BlockedTimeDraft(
      branchId: 3,
      startDate: DateTime(2026, 10, 5),
      endDate: DateTime(2026, 10, 7),
      reason: '  Eid holiday ',
    );
    expect(wholeDays.toJson(), {
      'branchId': 3,
      'startDate': '2026-10-05',
      'endDate': '2026-10-07',
      'reason': 'Eid holiday',
    });
    expect(wholeDays.problem, isNull);

    final backwards = BlockedTimeDraft(trainerId: 2, startDate: DateTime(2026, 10, 7), endDate: DateTime(2026, 10, 5));
    expect(backwards.problem, 'The end date is before the start date.');

    final hours = BlockedTimeDraft(
      trainerId: 2,
      startDate: DateTime(2026, 10, 5),
      endDate: DateTime(2026, 10, 5),
      startTime: '17:00',
      endTime: '14:00',
    );
    expect(hours.problem, 'The end time must be after the start time.');
    expect(hours.toJson()['startTime'], '17:00');
    expect(hours.toJson().containsKey('reason'), isFalse);
  });

  test('branch draft: trimmed text, rounded coordinates, no empty phone', () {
    final draft = BranchDraft(
      name: ' Dabouq Branch ',
      address: 'King Abdullah II St',
      city: 'Amman',
      position: const LatLng(31.98765432, 35.84123456),
      phone: '',
      openingTime: '06:00',
      closingTime: '23:00',
    );
    expect(draft.toJson(), {
      'name': 'Dabouq Branch',
      'address': 'King Abdullah II St',
      'city': 'Amman',
      'latitude': 31.987654,
      'longitude': 35.841235,
      'openingTime': '06:00',
      'closingTime': '23:00',
    });
  });

  test('availability says why a day is closed', () {
    final closed = Availability.fromJson({
      'date': '2026-10-05',
      'durationMinutes': 60,
      'slots': [],
      'closedReason': 'The branch is closed on this day (Eid holiday).',
    });
    expect(closed.slots, isEmpty);
    expect(closed.closedReason, 'The branch is closed on this day (Eid holiday).');
    expect(Availability.fromJson({'date': '2026-10-06', 'durationMinutes': 60, 'slots': []}).closedReason, isNull);
  });
}
