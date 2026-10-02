import '../utils/dates.dart';
import 'payment.dart';

enum BookingStatus {
  requested,
  accepted,
  paid,
  rejected,
  cancelled,
  expired;

  static BookingStatus fromJson(String value) => BookingStatus.values.firstWhere(
        (status) => status.name.toUpperCase() == value.toUpperCase(),
        orElse: () => BookingStatus.expired,
      );

  String get label => switch (this) {
        BookingStatus.requested => 'Waiting for trainer',
        BookingStatus.accepted => 'Awaiting payment',
        BookingStatus.paid => 'Confirmed',
        BookingStatus.rejected => 'Declined',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.expired => 'Expired',
      };

  /// Whether the booking still holds its time slot.
  bool get isActive =>
      this == BookingStatus.requested || this == BookingStatus.accepted || this == BookingStatus.paid;
}

class Booking {
  final int id;
  final BookingStatus status;
  final int trainerId;
  final String trainerName;
  final int memberId;
  final String memberName;
  final int branchId;
  final String branchName;
  final DateTime date; // date only
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double price;
  final String? memberNote;
  final String? trainerReply;
  final DateTime? respondBy;
  final DateTime? payBy;
  final bool canPay; // computed by the backend so the rules live in one place
  final DateTime? cancelUntil; // null when the booking can't be cancelled
  final bool canCancel;
  final PaymentInfo? payment; // set once paid, members only
  final bool cancelledByGym;
  final String? cancellationNote; // the gym's reason, when it cancelled

  /// The member's stars for this session once rated, and whether they can rate it now.
  final int? rating;
  final bool canReview;

  const Booking({
    required this.id,
    required this.status,
    required this.trainerId,
    required this.trainerName,
    required this.memberId,
    required this.memberName,
    required this.branchId,
    required this.branchName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.price,
    required this.memberNote,
    required this.trainerReply,
    required this.respondBy,
    required this.payBy,
    required this.canPay,
    required this.cancelUntil,
    required this.canCancel,
    required this.payment,
    this.cancelledByGym = false,
    this.cancellationNote,
    this.rating,
    this.canReview = false,
  });

  String get timeLabel => '$startTime – $endTime';

  String get dateLabel => prettyDate(date);

  /// Active and not yet ended, in gym (Amman) time.
  bool get isUpcoming => status.isActive && atTime(date, endTime).isAfter(gymNow());

  /// The most recent paid session that has already ended at [now], or null if there's none yet.
  /// The home screen offers to book that trainer again.
  static Booking? lastFinishedSession(Iterable<Booking> bookings, DateTime now) {
    Booking? last;
    for (final booking in bookings) {
      final ends = atTime(booking.date, booking.endTime);
      if (booking.status != BookingStatus.paid || ends.isAfter(now)) continue;
      if (last == null || ends.isAfter(atTime(last.date, last.endTime))) last = booking;
    }
    return last;
  }

  /// The latest session the member can still rate and hasn't skipped, for the home screen.
  static Booking? nextToRate(Iterable<Booking> bookings, Set<int> skipped) {
    Booking? latest;
    for (final booking in bookings) {
      if (!booking.canReview || skipped.contains(booking.id)) continue;
      if (latest == null || atTime(booking.date, booking.endTime).isAfter(atTime(latest.date, latest.endTime))) {
        latest = booking;
      }
    }
    return latest;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) => json[key] == null ? null : DateTime.parse(json[key] as String);
    final payment = json['payment'] as Map<String, dynamic>?;
    return Booking(
      id: (json['id'] as num).toInt(),
      status: BookingStatus.fromJson(json['status'] as String),
      trainerId: (json['trainerId'] as num).toInt(),
      trainerName: json['trainerName'] as String,
      memberId: (json['memberId'] as num).toInt(),
      memberName: json['memberName'] as String,
      branchId: (json['branchId'] as num).toInt(),
      branchName: json['branchName'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      memberNote: json['memberNote'] as String?,
      trainerReply: json['trainerReply'] as String?,
      respondBy: date('respondBy'),
      payBy: date('payBy'),
      canPay: json['canPay'] as bool? ?? false,
      cancelUntil: date('cancelUntil'),
      canCancel: json['canCancel'] as bool? ?? false,
      payment: payment == null ? null : PaymentInfo.fromJson(payment),
      cancelledByGym: json['cancelledBy'] == 'GYM',
      cancellationNote: json['cancellationNote'] as String?,
      rating: (json['rating'] as num?)?.toInt(),
      canReview: json['canReview'] as bool? ?? false,
    );
  }
}
