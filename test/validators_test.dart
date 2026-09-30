import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/utils/validators.dart';

/// Unit tests: run with  flutter test
void main() {
  group('Validators.password', () {
    test('rejects short passwords', () {
      expect(Validators.password('abc1'), isNotNull);
    });

    test('rejects passwords without a number', () {
      expect(Validators.password('abcdefgh'), isNotNull);
    });

    test('accepts a valid password', () {
      expect(Validators.password('abcdefg1'), isNull);
    });
  });

  group('Validators.phone', () {
    test('accepts Jordanian numbers with spaces', () {
      expect(Validators.phone('+962 79 123 4567'), isNull);
    });

    test('rejects letters', () {
      expect(Validators.phone('07abc'), isNotNull);
    });
  });

  test('cleanPhone removes spaces and dashes', () {
    expect(Validators.cleanPhone('+962 79-123 4567'), '+962791234567');
  });
}
