import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _themeStorageKey = 'app_theme_mode';
const _storage = FlutterSecureStorage();

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await _storage.read(key: _themeStorageKey);
    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.light; // Default to clean light mode
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    String val = mode == ThemeMode.light ? 'light' : 'dark';
    await _storage.write(key: _themeStorageKey, value: val);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
