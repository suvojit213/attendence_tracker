import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ValueNotifier<ThemeMode> {
  ThemeService() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? theme = prefs.getString('themeMode');
    if (theme == 'light') {
      value = ThemeMode.light;
    } else if (theme == 'dark') {
      value = ThemeMode.dark;
    } else {
      value = ThemeMode.light; // Default to light mode if no preference is saved
    }
  }

  void toggleTheme(bool isDark) async {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('themeMode', isDark ? 'dark' : 'light');
  }
}