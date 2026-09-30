import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers light / dark mode and tells the app to rebuild when it changes.
class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _mode = ThemeMode.system;   // follow the phone's setting until the user chooses

  ThemeMode get mode => _mode;

  /// Read the saved choice when the app starts.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _mode = ThemeMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  /// Switch to the opposite of what's on screen right now.
  Future<void> toggle(Brightness currentBrightness) async {
    _mode = currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode.name);
  }
}
