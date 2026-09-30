import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Saves the login token + user on the phone, so you stay logged in after closing the app.
///
/// Uses flutter_secure_storage: the values are encrypted (AES) with a key that lives in the
/// Android Keystore (iPhone: Keychain). Someone who copies the app's files only gets
/// unreadable bytes, because the key never leaves the phone's secure hardware.
class SessionStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  Future<void> save(String token, AppUser user) async {
    await _secure.write(key: _tokenKey, value: token);
    await _secure.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> readToken() async {
    await _deleteOldPlainTextCopy();
    try {
      return await _secure.read(key: _tokenKey);
    } on PlatformException {
      // The encryption key is gone (e.g. the phone was restored from a backup),
      // so the saved data can't be decrypted. Throw it away; the user just logs in again.
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
    await _secure.delete(key: _userKey);
  }

  /// Before, the token was kept in shared_preferences as plain text.
  /// Delete that old copy so it doesn't stay on the phone
  /// (anyone who was logged in simply logs in once more).
  Future<void> _deleteOldPlainTextCopy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
