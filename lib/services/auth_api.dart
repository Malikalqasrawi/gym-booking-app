import '../models/app_user.dart';
import '../models/two_factor.dart';
import 'api_client.dart';

/// A new session: the short-lived access token, the refresh token that renews it, and the user.
class AuthResult {
  final String token;
  final String refreshToken;
  final AppUser user;

  const AuthResult({required this.token, required this.refreshToken, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// The answer to a correct email and password: a session, or the second step of a two-factor login.
sealed class LoginResult {
  const LoginResult();
}

class LoggedIn extends LoginResult {
  final AuthResult session;

  const LoggedIn(this.session);
}

/// The account uses two-factor authentication: the next step needs [challengeToken].
class TwoFactorChallenge extends LoginResult {
  final String challengeToken;

  /// An admin who hasn't set up an authenticator app yet must do it before logging in.
  final bool setupRequired;

  const TwoFactorChallenge({required this.challengeToken, required this.setupRequired});
}

/// Client for the auth and current-user endpoints.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Returns the backend's confirmation message.
  Future<String> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await _client.post('/api/auth/signup', {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return json['message'] as String;
  }

  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    final json = await _client.post('/api/auth/verify', {'email': email, 'code': code});
    return AuthResult.fromJson(json);
  }

  Future<String> resendCode(String email) async {
    final json = await _client.post('/api/auth/resend-code', {'email': email});
    return json['message'] as String;
  }

  Future<LoginResult> login({required String email, required String password}) async {
    final json = await _client.post('/api/auth/login', {'email': email, 'password': password});
    return _loginResult(json);
  }

  /// Members only. The first time, the backend links the member with the same email or creates one.
  Future<LoginResult> loginWithGoogle(String idToken) async {
    final json = await _client.post('/api/auth/google', {'idToken': idToken});
    return _loginResult(json);
  }

  LoginResult _loginResult(Map<String, dynamic> json) {
    final step = json['twoFactor'] as String?;
    if (step == null) return LoggedIn(AuthResult.fromJson(json));
    return TwoFactorChallenge(
      challengeToken: json['challengeToken'] as String,
      setupRequired: step == 'SETUP_REQUIRED',
    );
  }

  /// Second login step: a 6-digit code from the authenticator app, or a recovery code.
  Future<AuthResult> loginWithCode({required String challengeToken, required String code}) async {
    final json = await _client.post('/api/auth/login/2fa', {'challengeToken': challengeToken, 'code': code});
    return AuthResult.fromJson(json);
  }

  /// An admin's first login: a new secret for their authenticator app.
  Future<TwoFactorSetup> startLoginSetup(String challengeToken) async {
    final json = await _client.post('/api/auth/login/2fa/setup', {'challengeToken': challengeToken});
    return TwoFactorSetup.fromJson(json);
  }

  /// Finishes an admin's first login with a code from the new app.
  Future<({List<String> recoveryCodes, AuthResult session})> confirmLoginSetup({
    required String challengeToken,
    required String code,
  }) async {
    final json = await _client.post('/api/auth/login/2fa/confirm', {'challengeToken': challengeToken, 'code': code});
    return (recoveryCodes: recoveryCodesFromJson(json), session: AuthResult.fromJson(json));
  }

  /// Sets an invited trainer's password with the emailed invite code and logs them in.
  Future<AuthResult> acceptInvite({
    required String email,
    required String code,
    required String password,
  }) async {
    final json = await _client.post('/api/auth/accept-invite', {
      'email': email,
      'code': code,
      'password': password,
    });
    return AuthResult.fromJson(json);
  }

  /// Asks for a password reset code. The backend answers the same whether or not the email has an account.
  Future<String> forgotPassword(String email) async {
    final json = await _client.post('/api/auth/forgot-password', {'email': email});
    return json['message'] as String;
  }

  /// Sets a new password with the emailed reset code. The user then logs in with it.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    final json = await _client.post('/api/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
    });
    return json['message'] as String;
  }

  /// Ends this device's session on the backend.
  Future<void> logout(String refreshToken) => _client.post('/api/auth/logout', {'refreshToken': refreshToken});

  /// Ends every session of the current user, on all devices.
  Future<void> logoutAll() => _client.post('/api/users/me/logout-all', {});

  /// Returns a new session for this device; the other devices are logged out.
  Future<AuthResult> changePassword({required String currentPassword, required String newPassword}) async {
    final json = await _client.post('/api/users/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return AuthResult.fromJson(json);
  }

  /// Starts setting up an authenticator app. [code] (from the current app, or a recovery code) is
  /// only needed when two-factor authentication is already on, to move it to a new phone.
  Future<TwoFactorSetup> startTwoFactorSetup({required String password, String? code}) async {
    final json = await _client.post('/api/users/me/2fa/setup', {
      'password': password,
      if (code != null) 'code': code,
    });
    return TwoFactorSetup.fromJson(json);
  }

  /// Turns two-factor authentication on with a code from the new app; returns the recovery codes.
  Future<List<String>> confirmTwoFactorSetup(String code) async {
    final json = await _client.post('/api/users/me/2fa/confirm', {'code': code});
    return recoveryCodesFromJson(json);
  }

  Future<void> disableTwoFactor({required String password, required String code}) =>
      _client.post('/api/users/me/2fa/disable', {'password': password, 'code': code});

  /// [phone] in international format. A new number has to be confirmed again.
  Future<AppUser> updatePhone(String phone) async {
    final json = await _client.put('/api/users/me/phone', {'phone': phone});
    return AppUser.fromJson(json);
  }

  /// Texts a code to the user's phone number. Returns how many seconds until another can be sent.
  Future<int> sendPhoneCode() async {
    final json = await _client.post('/api/users/me/phone/code', {});
    return (json['resendAfterSeconds'] as num?)?.toInt() ?? 60;
  }

  /// Confirms the phone number with the texted code.
  Future<AppUser> confirmPhone(String code) async {
    final json = await _client.post('/api/users/me/phone/confirm', {'code': code});
    return AppUser.fromJson(json);
  }

  Future<AppUser> me() async {
    final json = await _client.get('/api/users/me');
    return AppUser.fromJson(json);
  }
}
