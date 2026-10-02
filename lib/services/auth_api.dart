import '../models/app_user.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final AppUser user;

  const AuthResult({required this.token, required this.user});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
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

  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _client.post('/api/auth/login', {'email': email, 'password': password});
    return AuthResult.fromJson(json);
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

  Future<AppUser> me() async {
    final json = await _client.get('/api/users/me');
    return AppUser.fromJson(json);
  }
}
