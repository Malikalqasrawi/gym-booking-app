import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';

import '../config/google_config.dart';

/// Google sign-in failed for a reason other than the user closing the account picker.
class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message);

  final String message;
}

/// Asks Google for an ID token proving which Google account the user picked. The backend checks
/// the token and starts the app's own session, so no Google session is kept afterwards.
class GoogleAuth {
  static Future<void>? _initialization;

  static bool get isConfigured =>
      GoogleConfig.serverClientId.isNotEmpty && (!Platform.isIOS || GoogleConfig.iosClientId.isNotEmpty);

  /// The ID token, or null if the user closed the account picker.
  static Future<String?> idToken() async {
    try {
      await (_initialization ??= GoogleSignIn.instance.initialize(
        clientId: Platform.isIOS ? GoogleConfig.iosClientId : null,
        serverClientId: GoogleConfig.serverClientId,
      ));
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const GoogleAuthException("Google didn't send a sign-in token. Please try again.");
      }
      return token;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
          return null;
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
          throw GoogleAuthException(
              "Google sign-in isn't set up correctly for this app (${e.description ?? e.code.name}).");
        default:
          throw const GoogleAuthException('Google sign-in failed. Please try again.');
      }
    } finally {
      // So the next Google sign-in shows the account list again instead of reusing this account.
      try {
        await GoogleSignIn.instance.signOut();
      } on Exception {
        // Nothing to sign out of, e.g. Google sign-in never started.
      }
    }
  }
}
