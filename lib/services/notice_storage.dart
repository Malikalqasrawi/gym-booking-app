import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this phone which home-screen cards the member has dismissed.
class NoticeStorage {
  static const _cancellationsKey = 'dismissed_gym_cancellations';
  static const _ratingsKey = 'skipped_session_ratings';

  static Future<Set<int>> dismissed() => _read(_cancellationsKey);

  static Future<void> dismiss(int bookingId) => _add(_cancellationsKey, bookingId);

  /// Sessions the member chose not to rate ("Not now" on the home screen).
  static Future<Set<int>> skippedRatings() => _read(_ratingsKey);

  static Future<void> skipRating(int bookingId) => _add(_ratingsKey, bookingId);

  static Future<Set<int>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(key) ?? const <String>[]).map(int.tryParse).whereType<int>().toSet();
  }

  static Future<void> _add(String key, int bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = {...?prefs.getStringList(key), '$bookingId'};
    await prefs.setStringList(key, ids.toList());
  }
}
