import 'package:flutter/material.dart';

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeService with ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();

  ThemeService._internal();

  AppThemeMode _currentMode = AppThemeMode.system;

  AppThemeMode get currentMode => _currentMode;

  ThemeMode get themeMode {
    switch (_currentMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  bool isDarkMode(BuildContext context) {
    if (_currentMode == AppThemeMode.dark) return true;
    if (_currentMode == AppThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void setThemeMode(AppThemeMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }
}
