import '../utils/dates.dart';
import 'payment.dart';

/// Matches the Java enum `BookingStatus`.
enum BookingStatus {
  requested,
  accepted,
  paid,
  rejected,
  cancelled,
  expired;

  /// "ACCEPTED" → BookingStatus.accepted
  static BookingStatus fromJson(String value) => BookingStatus.values.firstWhere(
        (status) => status.name.toUpperCase() == value.toUpperCase(),
        orElse: () => BookingStatus.expired,
      );

  /// The words the app shows.
  String get label => switch (this) {
        BookingStatus.requested => 'Waiting for trainer',
        BookingStatus.accepted => 'Awaiting payment',
        BookingStatus.paid => 'Confirmed',
        BookingStatus.rejected => 'Declined',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.expired => 'Expired',
      };

  /// Still keeps the time slot (not finished in any way).
  bool get isActive =>
      this == BookingStatus.requested || this == BookingStatus.accepted || this == BookingStatus.paid;
}

/// The Dart version of the Java `BookingResponse` record.
class Booking {
  final int id;
  final BookingStatus status;
  final int trainerId;
  final String trainerName;
  final int memberId;
  final String memberName;
  final int branchId;
  final String branchName;
  final DateTime date; // the day only (time = 00:00)
  final String startTime; // "10:00"
  final String endTime; // "11:00"
  final int durationMinutes;
  final double price; // JOD
  final String? memberNote;
  final String? trainerReply;
  final DateTime? respondBy; // the trainer must answer before this
  final DateTime? payBy; // accepted: the member must pay before this
  final bool canPay; // worked out by the backend, so the rules live in one place
  final DateTime? cancelUntil; // the last moment Cancel works (null = can't be cancelled)
  final bool canCancel;
  final PaymentInfo? payment; // the receipt, once paid (members only)

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
  });

  /// "10:00 – 11:00"
  String get timeLabel => '$startTime – $endTime';

  /// "Wed 7 Oct"
  String get dateLabel => prettyDate(date);

  /// Upcoming = still active and the session hasn't ended yet (in gym time).
  bool get isUpcoming => status.isActive && atTime(date, endTime).isAfter(gymNow());

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
    );
  }
}
