import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../models/payment.dart';

/// Opens Stripe's own payment screen (Stripe calls it the "PaymentSheet").
///
/// The member types the card into STRIPE's screen, and the card goes from the phone straight to
/// Stripe. Our app and our Java backend never see the card number. The app only gets
/// "done" or "closed" back.
class StripeCheckout {
  StripeCheckout._();

  /// true = paid, false = the member closed the screen without paying.
  /// Throws [PaymentScreenException] if the screen couldn't open or failed.
  static Future<bool> pay(PaymentStart start, {required ThemeMode themeMode}) async {
    try {
      // 1. Which Stripe account to pay: its PUBLIC key, which our backend sent us
      Stripe.publishableKey = start.publishableKey;
      await Stripe.instance.applySettings();

      // 2. Prepare the screen for THIS payment (the clientSecret belongs to this booking only)
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: start.clientSecret,
          merchantDisplayName: start.merchantName,
          style: themeMode, // light / dark like the rest of the app
        ),
      );

      // 3. Show it. This waits until the card was charged, or throws "Canceled" if the member closes it.
      //    A declined card is handled INSIDE Stripe's screen (it says so and lets them try another card).
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
