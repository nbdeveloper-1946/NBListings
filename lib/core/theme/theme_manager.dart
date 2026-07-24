import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton theme controller with persisted preference.
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  ThemeManager._internal();

  static const String _prefsKey = 'crm_theme_is_dark';

  bool _isDarkMode = false;
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _initialized;

  /// Load preference from disk; fall back to platform brightness.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefsKey)) {
        _isDarkMode = prefs.getBool(_prefsKey) ?? false;
      } else {
        _isDarkMode =
            PlatformDispatcher.instance.platformBrightness == Brightness.dark;
      }
    } catch (_) {
      _isDarkMode =
          PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _persist();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDarkMode);
    } catch (_) {
      // Persistence failure should not break theme switching.
    }
  }
}
