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

  group('Validators.fullName', () {
    test('accepts names in any alphabet, with dots, apostrophes and hyphens', () {
      expect(Validators.fullName('Malik Qasrawi'), isNull);
      expect(Validators.fullName('مالك القصراوي'), isNull);
      expect(Validators.fullName("Anne-Marie O'Neil Jr."), isNull);
    });

    test('rejects links, digits and other text that could make an email look like phishing', () {
      expect(Validators.fullName('Visit http://evil.example'), 'Use letters only in your name');
      expect(Validators.fullName('Malik 2'), isNotNull);
      expect(Validators.fullName('  '), 'Full name is required');
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
}
