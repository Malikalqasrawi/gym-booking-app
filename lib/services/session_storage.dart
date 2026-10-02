import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Persists the tokens and user across app restarts. Values go through flutter_secure_storage,
/// encrypted with a key held in the Android Keystore / iOS Keychain.
class SessionStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<void> save(String token, String refreshToken, AppUser user) async {
    await saveTokens(token, refreshToken);
    await saveUser(user);
  }

  Future<void> saveTokens(String token, String refreshToken) async {
    await _secure.write(key: _tokenKey, value: token);
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> saveUser(AppUser user) async {
    await _secure.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<String?> readToken() async {
    await _deleteOldPlainTextCopy();
    try {
      return await _secure.read(key: _tokenKey);
    } on PlatformException {
      // The encryption key is gone (such as after a device restore), so the data can't be
      // decrypted. Drop it and let the user log in again.
      await _secure.deleteAll();
      return null;
    }
  }

  Future<AppUser?> readUser() async {
    final raw = await _secure.read(key: _userKey);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _refreshTokenKey);
    await _secure.delete(key: _userKey);
  }

  /// Older versions kept the session in shared_preferences as plain text; remove that copy.
  Future<void> _deleteOldPlainTextCopy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
