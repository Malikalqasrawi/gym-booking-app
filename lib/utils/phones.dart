import 'package:phone_form_field/phone_form_field.dart';

/// Phone numbers are saved in international format, e.g. +962791234567. Numbers saved before the
/// country picker have no country code; those are Jordanian.
class Phones {
  static const defaultCountry = IsoCode.JO;

  /// Shown at the top of the country list.
  static const favoriteCountries = [IsoCode.JO, IsoCode.PS, IsoCode.SA, IsoCode.AE, IsoCode.IQ, IsoCode.EG];

  /// For a phone field: the saved number, or an empty Jordanian one.
  static PhoneController controller([String? saved]) =>
      PhoneController(initialValue: parse(saved) ?? const PhoneNumber(isoCode: defaultCountry, nsn: ''));

  /// Null if there is no number, or it can't be read.
  static PhoneNumber? parse(String? saved) {
    if (saved == null || saved.trim().isEmpty) return null;
    try {
      return PhoneNumber.parse(saved, callerCountry: defaultCountry);
    } on Exception {
      return null;
    }
  }

  /// A saved number to show, e.g. "+962 7 9123 4567". Anything unexpected is shown as it was saved.
  static String display(String saved) {
    final number = parse(saved);
    if (number == null || !number.isValid()) return saved;
    return '+${number.countryCode} ${number.formatNsn()}';
  }
}
