import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_theme_mode';

/// Only light/dark are offered in the UI toggle (no "system" option), so the
/// persisted value is always one of these two — `ThemeMode.system` is never
/// written, only ever a fallback default before prefs load.
final appThemeModeProvider =
    StateNotifierProvider<AppThemeModeNotifier, ThemeMode>((ref) {
      return AppThemeModeNotifier();
    });

class AppThemeModeNotifier extends StateNotifier<ThemeMode> {
  AppThemeModeNotifier() : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    if (saved == 'dark') {
      state = ThemeMode.dark;
    } else if (saved == 'light') {
      state = ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, state == ThemeMode.dark ? 'dark' : 'light');
  }
}
