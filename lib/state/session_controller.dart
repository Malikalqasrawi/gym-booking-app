import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_api.dart';
import '../services/session_storage.dart';

/// Knows WHO is logged in. When it changes, it calls notifyListeners()
/// and the widgets listening to it rebuild (e.g. switch from the login screen to Home).
class SessionController extends ChangeNotifier {
  SessionController({
    required ApiClient apiClient,
    required AuthApi authApi,
    required SessionStorage storage,
  })  : _apiClient = apiClient,
        _authApi = authApi,
        _storage = storage;

  final ApiClient _apiClient;
  final AuthApi _authApi;
  final SessionStorage _storage;

  AppUser? _user;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Called once when the app starts: are we still logged in from last time?
  Future<void> restore() async {
    final token = await _storage.readToken();
    if (token == null) return;

    _apiClient.token = token;
    try {
      // Ask the backend who this token belongs to (also checks it hasn't expired)
      _user = await _authApi.me();
      await _storage.save(token, _user!);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Token expired or invalid: log out
        await _clear();
      } else {
        // Backend is off, too many requests (429), server error...: the token may still be fine,
        // so trust the saved user for now instead of logging out
        _user = await _storage.readUser();
      }
    }
  }

  /// Called after a successful login or email verification.
  Future<void> startSession(AuthResult result) async {
    _apiClient.token = result.token;
    await _storage.save(result.token, result.user);
    _user = result.user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    _apiClient.token = null;
    _user = null;
    await _storage.clear();
  }
}
