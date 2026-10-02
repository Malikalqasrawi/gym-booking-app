/// A new secret for an authenticator app, from the backend's setup endpoints.
class TwoFactorSetup {
  /// The Base32 secret, for typing into the app by hand.
  final String secret;

  /// The otpauth:// link shown as a QR code; it holds the secret and the account name.
  final String otpauthUri;

  const TwoFactorSetup({required this.secret, required this.otpauthUri});

  factory TwoFactorSetup.fromJson(Map<String, dynamic> json) {
    return TwoFactorSetup(
      secret: json['secret'] as String,
      otpauthUri: json['otpauthUri'] as String,
    );
  }

  /// The secret in groups of 4 characters, easier to read and type: "ABCD EFGH ...".
  String get groupedSecret {
    final groups = <String>[];
    for (var i = 0; i < secret.length; i += 4) {
      groups.add(secret.substring(i, i + 4 > secret.length ? secret.length : i + 4));
    }
    return groups.join(' ');
  }
}

/// Reads the recovery codes from a backend response.
List<String> recoveryCodesFromJson(Map<String, dynamic> json) =>
    (json['recoveryCodes'] as List<dynamic>).map((code) => code as String).toList();
