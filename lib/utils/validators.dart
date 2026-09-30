/// Form checks that run on the phone BEFORE calling the backend.
/// They mirror the Java rules in SignUpRequest, so users see mistakes instantly.
/// (The backend still checks again: never trust the app alone.)
class Validators {
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length > 100) return 'Full name is too long';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(value.trim())) return 'Email is not valid';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleanPhone(value))) {
      return 'Phone must be 8-15 digits, optionally starting with +';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Za-z]').hasMatch(value) || !RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain a letter and a number';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }

  static String? code(String? value) {
    if (value == null || !RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Enter the 6-digit code';
    }
    return null;
  }

  /// "+962 79 123 4567" → "+962791234567"
  static String cleanPhone(String value) => value.replaceAll(RegExp(r'[\s-]'), '');
}
