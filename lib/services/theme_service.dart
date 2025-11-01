import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _key = 'app_theme_mode';
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      case 'system':
        themeMode.value = ThemeMode.system;
        break;
      default:
        themeMode.value = ThemeMode.light;
    }
  }

  Future<void> toggleLightDark() async {
    final next = themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeMode.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next == ThemeMode.dark ? 'dark' : 'light');
  }
}


