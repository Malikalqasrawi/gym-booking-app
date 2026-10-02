import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/utils/validators.dart';

void main() {
  group('Validators.password', () {
    test('rejects short passwords', () {
      expect(Validators.password('abc1'), isNotNull);
    });

    test('rejects passwords without a number', () {
      expect(Validators.password('abcdefgh'), isNotNull);
    });

    test('rejects passwords over 72 characters, like the backend', () {
      expect(Validators.password('a1' * 36), isNull);
      expect(Validators.password('${'a1' * 36}b'), isNotNull);
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

  group('Validators.hourlyRate', () {
    test('accepts whole and decimal rates', () {
      expect(Validators.hourlyRate('20'), isNull);
      expect(Validators.hourlyRate('22.5'), isNull);
    });

    test('rejects text, too many decimals and out-of-range values', () {
      expect(Validators.hourlyRate('abc'), isNotNull);
      expect(Validators.hourlyRate('20.1234'), isNotNull);
      expect(Validators.hourlyRate('0.5'), isNotNull);
      expect(Validators.hourlyRate('600'), isNotNull);
    });
  });

  test('cleanPhone removes spaces and dashes', () {
    expect(Validators.cleanPhone('+962 79-123 4567'), '+962791234567');
  });
}
