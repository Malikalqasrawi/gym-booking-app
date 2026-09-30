import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../models/payment.dart';

/// Presents Stripe's PaymentSheet. Card details go from the device straight to Stripe;
/// neither the app nor the backend ever sees them.
class StripeCheckout {
  StripeCheckout._();

  /// Returns true when paid, false when the member dismisses the sheet.
  /// Throws [PaymentScreenException] if the sheet fails.
  static Future<bool> pay(PaymentStart start, {required ThemeMode themeMode}) async {
    try {
      Stripe.publishableKey = start.publishableKey;
      await Stripe.instance.applySettings();

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: start.clientSecret,
          merchantDisplayName: start.merchantName,
          style: themeMode,
        ),
      );

      // Completes once the card is charged. Declined cards are handled inside the sheet.
      await Stripe.instance.presentPaymentSheet();
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return false;
      }
      throw PaymentScreenException(e.error.localizedMessage ?? e.error.message ?? 'The payment screen failed.');
    }
  }
}

class PaymentScreenException implements Exception {
  PaymentScreenException(this.message);

  final String message;

  @override
  String toString() => message;
}
