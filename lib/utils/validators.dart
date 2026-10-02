/// Client-side form validation mirroring the backend's request rules.
/// The backend validates again.
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
    if (value.length > 72) return 'Password can be at most 72 characters';
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

  static String? hourlyRate(String? value) {
    final text = value?.trim() ?? '';
    final rate = double.tryParse(text);
    if (rate == null || !RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(text)) {
      return 'Use a number like 20 or 22.5';
    }
    if (rate < 1 || rate > 500) return 'Between 1 and 500 JOD';
    return null;
  }

  static String? yearsOfExperience(String? value) {
    final years = int.tryParse(value?.trim() ?? '');
    if (years == null) return 'Required';
    if (years > 60) return 'At most 60';
    return null;
  }

  static String cleanPhone(String value) => value.replaceAll(RegExp(r'[\s-]'), '');
}
