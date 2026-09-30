import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/utils/dates.dart';

void main() {
  test('isoDate pads month and day', () {
    expect(isoDate(DateTime(2026, 10, 4)), '2026-10-04');
  });

  test('backendDayName matches Java DayOfWeek names', () {
    expect(backendDayName(DateTime.monday), 'MONDAY');
    expect(backendDayName(DateTime.sunday), 'SUNDAY');
  });

  test('prettyDate', () {
    expect(prettyDate(DateTime(2026, 10, 4)), 'Sun 4 Oct');
  });
}
