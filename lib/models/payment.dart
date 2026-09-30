enum PaymentStatus {
  pending,
  succeeded,
  refunded;

  static PaymentStatus fromJson(String value) => PaymentStatus.values.firstWhere(
        (status) => status.name.toUpperCase() == value.toUpperCase(),
        orElse: () => PaymentStatus.pending,
      );
}

class PaymentInfo {
  final PaymentStatus status;
  final double amount;
  final String method;
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

/// What the backend returns to start paying for one booking with Stripe's PaymentSheet.
class PaymentStart {
  final int bookingId;
  final String? clientSecret;
  final String publishableKey;
  final String merchantName;
  final double amount;
  final DateTime payBy; // the slot is released if unpaid by then
  final DateTime cancelUntilAfterPaying; // refundable cancellation deadline once paid
  final bool alreadyPaid; // payment already went through: skip the sheet and just confirm

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
