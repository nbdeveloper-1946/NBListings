import 'dart:ui';
import 'package:flutter/material.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  
  ThemeManager._internal() {
    _isDarkMode = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
  }

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
