import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/api_exception.dart';
import '../services/auth_api.dart';
import '../services/session_storage.dart';

/// The logged-in user. Keeps the ApiClient tokens and the stored session in sync.
class SessionController extends ChangeNotifier {
  SessionController({
    required ApiClient apiClient,
    required AuthApi authApi,
    required SessionStorage storage,
  })  : _apiClient = apiClient,
        _authApi = authApi,
        _storage = storage {
    _apiClient.onTokensRefreshed = (token, refreshToken) => _storage.saveTokens(token, refreshToken);
    _apiClient.onSessionEnded = _sessionEnded;
  }

  final ApiClient _apiClient;
  final AuthApi _authApi;
  final SessionStorage _storage;

  AppUser? _user;
  String? _notice;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// A message for the login screen, such as why the user was logged out. Returned only once.
  String? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  Future<void> restore() async {
    final token = await _storage.readToken();
    if (token == null) return;

    _apiClient.token = token;
    _apiClient.refreshToken = await _storage.readRefreshToken();
    try {
      _user = await _authApi.me(); // renews the access token first if it has expired
      await _storage.saveUser(_user!);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _clear();
      } else {
        // Backend unreachable, rate-limited or failing: the session may still be valid,
        // so keep the saved user instead of logging out.
        _user = await _storage.readUser();
      }
    }
  }

  Future<void> startSession(AuthResult result) async {
    _apiClient.token = result.token;
    _apiClient.refreshToken = result.refreshToken;
    await _storage.save(result.token, result.refreshToken, result.user);
    _user = result.user;
    notifyListeners();
  }

  /// Logs out on this device right away, then tells the backend to end the session.
  Future<void> logout() async {
    final refreshToken = _apiClient.refreshToken;
    await _clear();
    notifyListeners();
    if (refreshToken == null) return;
    try {
      await _authApi.logout(refreshToken);
    } on ApiException {
      // Offline: the session stays valid on the backend until it expires, but this device has
      // forgotten it.
    }
  }

  /// Ends every session on every device, including this one. Throws if the backend can't be reached.
  Future<void> logoutAllDevices() async {
    await _authApi.logoutAll();
    await _clear();
    notifyListeners();
  }

  /// Changes the password; this device gets a new session and the others are logged out.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final result = await _authApi.changePassword(currentPassword: currentPassword, newPassword: newPassword);
    await startSession(result);
  }

  /// Updates the saved user after two-factor authentication was turned on or off.
  Future<void> setTwoFactorEnabled(bool enabled) async {
    final user = _user?.withTwoFactor(enabled);
    if (user == null) return;
    _user = user;
    await _storage.saveUser(user);
    notifyListeners();
  }

  /// Called by ApiClient when the session can't be renewed, e.g. after the password was changed
  /// on another device.
  Future<void> _sessionEnded() async {
    if (_user == null) return;
    _notice = 'Your session has ended. Please log in again.';
    await _clear();
    notifyListeners();
  }

  Future<void> _clear() async {
    _apiClient.token = null;
    _apiClient.refreshToken = null;
    _user = null;
    await _storage.clear();
  }
}
