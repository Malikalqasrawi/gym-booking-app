const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _backendDays = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];

/// Today's date at the gym. Amman is UTC+3 year-round, so this ignores the device
/// time zone and matches the backend's calculation.
DateTime gymToday() {
  final amman = DateTime.now().toUtc().add(const Duration(hours: 3));
  return DateTime(amman.year, amman.month, amman.day);
}

/// Current Amman local time, for comparing with session times (also Amman local).
DateTime gymNow() {
  final amman = DateTime.now().toUtc().add(const Duration(hours: 3));
  return DateTime(amman.year, amman.month, amman.day, amman.hour, amman.minute, amman.second);
}

DateTime atTime(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  return DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1]));
}

String isoDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// Maps a Dart weekday (1 = Monday) to a Java DayOfWeek name.
String backendDayName(int weekday) => _backendDays[weekday - 1];

String shortDayFromBackend(String dayOfWeek) => _weekdayShort[_backendDays.indexOf(dayOfWeek)];

String weekdayShort(DateTime date) => _weekdayShort[date.weekday - 1];

String monthShort(DateTime date) => _monthShort[date.month - 1];

String prettyDate(DateTime date) => '${weekdayShort(date)} ${date.day} ${monthShort(date)}';

String prettyDateTime(DateTime dateTime) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${prettyDate(dateTime)}, ${two(dateTime.hour)}:${two(dateTime.minute)}';
}
