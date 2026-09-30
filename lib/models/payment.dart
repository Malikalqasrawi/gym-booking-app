/// Matches the Java enum `PaymentStatus`.
enum PaymentStatus {
  pending,
  succeeded,
  refunded;

  static PaymentStatus fromJson(String value) => PaymentStatus.values.firstWhere(
        (status) => status.name.toUpperCase() == value.toUpperCase(),
        orElse: () => PaymentStatus.pending,
      );
}

/// The receipt part of a booking (Java `PaymentInfo`). Only there once something was paid.
class PaymentInfo {
  final PaymentStatus status;
  final double amount; // JOD
  final String method; // "Visa •••• 4242"
  final DateTime? paidAt;
  final DateTime? refundedAt;

  const PaymentInfo({
    required this.status,
    required this.amount,
    required this.method,
    required this.paidAt,
    required this.refundedAt,
  });

  bool get isRefunded => status == PaymentStatus.refunded;

  factory PaymentInfo.fromJson(Map<String, dynamic> json) => PaymentInfo(
        status: PaymentStatus.fromJson(json['status'] as String),
        amount: (json['amount'] as num).toDouble(),
        method: json['method'] as String,
        paidAt: _date(json['paidAt']),
        refundedAt: _date(json['refundedAt']),
      );
}

/// What POST /api/bookings/{id}/payment answers (Java `PaymentStartResponse`):
/// everything needed to open Stripe's payment screen for ONE booking.
class PaymentStart {
  final int bookingId;
  final String? clientSecret; // opens Stripe's screen for this payment only
  final String publishableKey; // Stripe's PUBLIC key (pk_test_...), safe to have in the app
  final String merchantName; // shown at the top of Stripe's screen
  final double amount; // JOD
  final DateTime payBy; // pay before this, or the time is released
  final DateTime cancelUntilAfterPaying; // once paid, cancelling (with refund) is possible until this
  final bool alreadyPaid; // the money already arrived: skip Stripe's screen, just confirm

  const PaymentStart({
    required this.bookingId,
    required this.clientSecret,
    required this.publishableKey,
    required this.merchantName,
    required this.amount,
    required this.payBy,
    required this.cancelUntilAfterPaying,
    required this.alreadyPaid,
  });

  factory PaymentStart.fromJson(Map<String, dynamic> json) => PaymentStart(
        bookingId: (json['bookingId'] as num).toInt(),
        clientSecret: json['clientSecret'] as String?,
        publishableKey: json['publishableKey'] as String,
        merchantName: json['merchantName'] as String,
        amount: (json['amount'] as num).toDouble(),
        payBy: DateTime.parse(json['payBy'] as String),
        cancelUntilAfterPaying: DateTime.parse(json['cancelUntilAfterPaying'] as String),
        alreadyPaid: json['alreadyPaid'] as bool? ?? false,
      );
}

DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);
