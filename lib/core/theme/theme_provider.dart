import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _key = 'theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getString(_key);
    if (val != null) {
      state = ThemeMode.values.firstWhere((e) => e.name == val, orElse: () => ThemeMode.system);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

final dynamicColorProvider = StateNotifierProvider<DynamicColorNotifier, bool>((ref) {
  return DynamicColorNotifier();
});

class DynamicColorNotifier extends StateNotifier<bool> {
  DynamicColorNotifier() : super(true) {
    _load();
  }

  static const _key = 'dynamic_color_enabled';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? true;
  }

  Future<void> toggle(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

final manualThemeColorProvider = StateNotifierProvider<ManualThemeColorNotifier, int>((ref) {
  return ManualThemeColorNotifier();
});

class ManualThemeColorNotifier extends StateNotifier<int> {
  ManualThemeColorNotifier() : super(0xFF6750A4) { // Default Purple
    _load();
  }

  static const _key = 'manual_theme_color';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_key) ?? 0xFF6750A4;
  }

  Future<void> setColor(int colorValue) async {
    state = colorValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, colorValue);
  }
}
