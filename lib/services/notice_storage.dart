import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this phone which home-screen notices the member has dismissed.
class NoticeStorage {
  static const _key = 'dismissed_gym_cancellations';

  static Future<Set<int>> dismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).map(int.tryParse).whereType<int>().toSet();
  }

  static Future<void> dismiss(int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = {...?prefs.getStringList(_key), '$bookingId'};
    await prefs.setStringList(_key, ids.toList());
  }
}
