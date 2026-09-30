/// 10.0.2.2 is how the Android emulator reaches the host machine. Use http://localhost:8080
/// on the iOS simulator and the host's LAN IP on a physical device.
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8080';

  static const Duration timeout = Duration(seconds: 10);
}
