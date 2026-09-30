/// Where the Java backend lives.
///
/// The Android emulator is a separate "virtual phone", so "localhost" inside it
/// means the emulator itself, NOT your Mac. 10.0.2.2 is the emulator's special
/// address for "the computer I'm running on".
///
///   Android emulator  → http://10.0.2.2:8080
///   iPhone simulator  → http://localhost:8080
///   Physical phone    → `http://<your Mac's Wi-Fi IP>:8080`  (e.g. http://192.168.1.20:8080)
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080';

  /// How long to wait for the server before giving up.
  static const Duration timeout = Duration(seconds: 10);
}
