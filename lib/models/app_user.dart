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
  final String phone;
  final UserRole role;
  final String title;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.title,
  });

  String get firstName => fullName.split(' ').first;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: (json['phone'] as String?) ?? '',
      role: UserRole.fromJson(json['role'] as String),
      title: (json['title'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role.name.toUpperCase(),
        'title': title,
      };
}
