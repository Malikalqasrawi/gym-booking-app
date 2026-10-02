import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/booking.dart';
import 'package:gym_booking/models/payment.dart';

void main() {
  Map<String, dynamic> json({String status = 'ACCEPTED', Map<String, dynamic>? payment}) => {
        'id': 58,
        'status': status,
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
        'memberNote': null,
        'trainerReply': null,
        'respondBy': '2026-10-01T09:00',
        'payBy': status == 'ACCEPTED' ? '2026-09-30T21:00' : null,
        'canPay': status == 'ACCEPTED',
        'cancelUntil': '2026-10-06T10:00',
        'canCancel': true,
        'payment': payment,
      };

  test('accepted booking: can pay, has a deadline, no receipt yet', () {
    final booking = Booking.fromJson(json());
    expect(booking.status, BookingStatus.accepted);
    expect(booking.status.label, 'Awaiting payment');
    expect(booking.canPay, isTrue);
    expect(booking.payBy, DateTime(2026, 9, 30, 21, 0));
    expect(booking.payment, isNull);
  });

  test('paid booking: receipt with card label', () {
    final booking = Booking.fromJson(json(status: 'PAID', payment: {
      'status': 'SUCCEEDED',
      'amount': 28.21,
      'currency': 'USD',
      'method': 'Visa •••• 4242',
      'paidAt': '2026-09-30T10:15',
      'refundedAt': null,
    }));
    expect(booking.status, BookingStatus.paid);
    expect(booking.status.label, 'Confirmed');
    expect(booking.status.isActive, isTrue);
    expect(booking.canPay, isFalse);
    expect(booking.payment!.status, PaymentStatus.succeeded);
    expect(booking.payment!.method, 'Visa •••• 4242');
    expect(booking.payment!.amount, 28.21);
    expect(booking.payment!.currency, 'USD');
    expect(booking.payment!.isRefunded, isFalse);
    expect(booking.cancelUntil, DateTime(2026, 10, 6, 10, 0));
  });

  test('refunded payment is recognised', () {
    final booking = Booking.fromJson(json(status: 'CANCELLED', payment: {
      'status': 'REFUNDED',
      'amount': 20.0,
      'currency': 'JOD',
      'method': 'Visa •••• 4242',
      'paidAt': '2026-09-30T10:15',
      'refundedAt': '2026-10-02T08:00',
    }));
    expect(booking.status.isActive, isFalse);
    expect(booking.payment!.isRefunded, isTrue);
    expect(booking.payment!.refundedAt, DateTime(2026, 10, 2, 8, 0));
  });

  test('a booking cancelled by the gym carries its note', () {
    final booking = Booking.fromJson({
      ...json(status: 'CANCELLED'),
      'cancelledBy': 'GYM',
      'cancellationNote': 'Your trainer is no longer available.',
    });
    expect(booking.cancelledByGym, isTrue);
    expect(booking.cancellationNote, 'Your trainer is no longer available.');
    expect(Booking.fromJson(json(status: 'CANCELLED')).cancelledByGym, isFalse);
  });
}
