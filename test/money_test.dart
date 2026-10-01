import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/utils/money.dart';

void main() {
  test('whole dinars have no decimals', () {
    expect(formatJod(20), '20 JOD');
    expect(formatJod(33.0), '33 JOD');
  });

  test('only the needed decimals are shown', () {
    expect(formatJod(13.5), '13.5 JOD');
    expect(formatJod(12.345), '12.345 JOD');
  });

  test('other currencies use 2 decimals', () {
    expect(formatMoney(28.21, 'USD'), '28.21 USD');
    expect(formatMoney(31.7, 'usd'), '31.70 USD');
    expect(formatMoney(20, 'JOD'), '20 JOD');
  });

  test('prices match the backend formula (rate × minutes / 60)', () {
    expect(formatJod(18 * 45 / 60), '13.5 JOD');
    expect(formatJod(22 * 90 / 60), '33 JOD');
  });
}
