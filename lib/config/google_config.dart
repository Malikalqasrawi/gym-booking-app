/// Google sign-in client IDs, passed at build time so they stay out of the repository:
/// `flutter run --dart-define-from-file=google_sign_in.json` (see google_sign_in.example.json).
/// Without them the Google button explains that Google sign-in isn't set up.
class GoogleConfig {
  /// The "Web application" client ID; the backend accepts ID tokens issued for it.
  static const String serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// The "iOS" client ID. Android needs none: Google recognizes the app by its package name and
  /// signing key.
  static const String iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
}
