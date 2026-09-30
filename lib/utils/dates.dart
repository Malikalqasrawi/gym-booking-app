// Small date helpers, so we don't need an extra package for 3 functions.

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _backendDays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

/// The gym is in Amman. Jordan uses UTC+3 all year, so "today at the gym" is
/// UTC time + 3 hours — no matter what time zone the phone or emulator is set to.
/// (The backend calculates dates the same way, so both always agree.)
DateTime gymToday() {
  final amman = DateTime.now().toUtc().add(const Duration(hours: 3));
  return DateTime(amman.year, amman.month, amman.day);
}

/// The time right now at the gym (Amman), as a plain date + time, e.g. 2026-10-04 09:15.
/// Used to compare with session times, which are also Amman times.
DateTime gymNow() {
  final amman = DateTime.now().toUtc().add(const Duration(hours: 3));
  return DateTime(amman.year, amman.month, amman.day, amman.hour, amman.minute, amman.second);
}

/// A date plus an "HH:mm" time: (2026-10-04, "09:30") → 2026-10-04 09:30
DateTime atTime(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
}

/// DateTime(2026, 10, 4) → "2026-10-04"  (the format the Java backend expects)
String isoDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// Dart's weekday (Monday = 1 … Sunday = 7) → Java's DayOfWeek name ("MONDAY" …).
String backendDayName(int weekday) => _backendDays[weekday - 1];

/// "SUNDAY" → "Sun"
String shortDayFromBackend(String dayOfWeek) => _weekdayShort[_backendDays.indexOf(dayOfWeek)];

/// "Sun"
String weekdayShort(DateTime date) => _weekdayShort[date.weekday - 1];

/// "Oct"
String monthShort(DateTime date) => _monthShort[date.month - 1];

/// "Sun 4 Oct"
String prettyDate(DateTime date) => '${weekdayShort(date)} ${date.day} ${monthShort(date)}';

/// "Sun 4 Oct, 09:30"
String prettyDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${prettyDate(dateTime)}, ${two(dateTime.hour)}:${two(dateTime.minute)}';
}
