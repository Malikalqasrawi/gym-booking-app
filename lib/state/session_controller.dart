import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_api.dart';
import '../services/session_storage.dart';

/// The logged-in user. Keeps the ApiClient token and the stored session in sync.
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

  Future<void> restore() async {
    final token = await _storage.readToken();
    if (token == null) return;

    _apiClient.token = token;
    try {
      _user = await _authApi.me();
      await _storage.save(token, _user!);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clear();
      } else {
        // Backend unreachable, rate-limited or failing: the token may still be valid,
        // so keep the saved user instead of logging out.
        _user = await _storage.readUser();
      }
    }
  }

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
