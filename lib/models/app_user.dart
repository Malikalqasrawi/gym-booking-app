enum UserRole {
  member,
  trainer,
  admin;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.member,
    );
  }
}

class AppUser {
  final int id;
  final String fullName;
  final String email;
  /// In international format, e.g. +962791234567.
  final String phone;

  /// Confirmed with a code sent by SMS. Members need this before their first booking.
  final bool phoneVerified;
  final UserRole role;
  final String title;
  final bool twoFactorEnabled;

  /// False after signing up with Google, until a password is set with "Forgot password".
  final bool hasPassword;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.phoneVerified = false,
    required this.role,
    required this.title,
    this.twoFactorEnabled = false,
    this.hasPassword = true,
  });

  String get firstName => fullName.split(' ').first;

  /// Admins can't turn two-factor authentication off.
  bool get mustUseTwoFactor => role == UserRole.admin;

  /// A member who signed up with Google, which doesn't share phone numbers.
  bool get needsPhone => role == UserRole.member && phone.isEmpty;

  /// Members confirm their number by SMS before booking.
  bool get mustConfirmPhone => role == UserRole.member && !phoneVerified;

  AppUser withTwoFactor(bool enabled) => AppUser(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        phoneVerified: phoneVerified,
        role: role,
        title: title,
        twoFactorEnabled: enabled,
        hasPassword: hasPassword,
      );

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: (json['phone'] as String?) ?? '',
      phoneVerified: (json['phoneVerified'] as bool?) ?? false,
      role: UserRole.fromJson(json['role'] as String),
      title: (json['title'] as String?) ?? '',
      twoFactorEnabled: (json['twoFactorEnabled'] as bool?) ?? false,
      hasPassword: (json['hasPassword'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'phoneVerified': phoneVerified,
        'role': role.name.toUpperCase(),
        'title': title,
        'twoFactorEnabled': twoFactorEnabled,
        'hasPassword': hasPassword,
      };
}
