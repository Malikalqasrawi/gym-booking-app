import '../models/app_user.dart';
import 'api_client.dart';

/// What we get back after login or verification.
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

/// Dart functions for each Java endpoint in AuthController / UserController.
/// Screens call these instead of writing URLs themselves.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// POST /api/auth/signup  → returns the server's message
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

  /// POST /api/auth/verify
  Future<AuthResult> verifyEmail({required String email, required String code}) async {
    final json = await _client.post('/api/auth/verify', {'email': email, 'code': code});
    return AuthResult.fromJson(json);
  }

  /// POST /api/auth/resend-code
  Future<String> resendCode(String email) async {
    final json = await _client.post('/api/auth/resend-code', {'email': email});
    return json['message'] as String;
  }

  /// POST /api/auth/login
  Future<AuthResult> login({required String email, required String password}) async {
    final json = await _client.post('/api/auth/login', {'email': email, 'password': password});
    return AuthResult.fromJson(json);
  }

  /// GET /api/users/me  (needs the token)
  Future<AppUser> me() async {
    final json = await _client.get('/api/users/me');
    return AppUser.fromJson(json);
  }
}
