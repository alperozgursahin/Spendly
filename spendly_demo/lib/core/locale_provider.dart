import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { tr, en }

const _prefsKey = 'app_language';

/// Mirrors [appLanguageProvider]'s state for the handful of call sites that
/// have no [WidgetRef] available (e.g. `friendlyErrorMessage`, called from
/// plain `catch` blocks, and GoRouter's non-reactive route-fallback titles).
/// Kept in sync by [AppLanguageNotifier]; never written to directly.
AppLanguage currentAppLanguage = AppLanguage.tr;

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
      return AppLanguageNotifier();
    });

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.tr) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);

    if (saved == 'en') {
      state = AppLanguage.en;
    } else if (saved == 'tr') {
      state = AppLanguage.tr;
    }
    currentAppLanguage = state;
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    currentAppLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.name);
  }

  Future<void> toggle() {
    return setLanguage(state == AppLanguage.tr ? AppLanguage.en : AppLanguage.tr);
  }
}
