// lib/provider/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefIsDarkMode = 'isDarkMode';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode;

  // Accept an initial value
  ThemeProvider(bool isDark)
      : _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefIsDarkMode, isDark);
  }
}
