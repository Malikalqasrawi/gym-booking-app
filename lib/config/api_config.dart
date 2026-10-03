/// Where the backend is. Set it when building, e.g.
/// `flutter build apk --dart-define=API_URL=https://api.example.com`.
///
/// The default, 10.0.2.2, is how the Android emulator reaches the computer it runs on. On a phone
/// connected by USB, run `adb reverse tcp:8080 tcp:8080` and use `--dart-define=API_URL=http://localhost:8080`;
/// on the iOS simulator use http://localhost:8080. Plain http only works in debug builds.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

  static const Duration timeout = Duration(seconds: 10);
}
