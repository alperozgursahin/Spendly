import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// `intl` exports its own `TextDirection` class; hiding it keeps
// `AppLanguage.textDirection` bound to Flutter's dart:ui enum, which is what
// `Directionality` in main.dart expects.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

/// Languages prepared for Splixa's global rollout.
///
/// English is the source and guaranteed fallback locale. A language is only
/// offered in the picker once [translationReady] is true, which means a
/// complete dictionary exists under `lib/core/l10n/`. The remaining locales
/// stay catalogued so detection, persistence and RTL layout can expand to
/// them by adding one dictionary file — no state-management migration.
enum AppLanguage {
  en('en', 'English', 'English', translationReady: true),
  tr('tr', 'Turkish', 'Türkçe', translationReady: true),
  es('es', 'Spanish', 'Español', translationReady: true),
  pt('pt', 'Portuguese', 'Português', translationReady: true),
  de('de', 'German', 'Deutsch', translationReady: true),
  fr('fr', 'French', 'Français', translationReady: true),
  it('it', 'Italian', 'Italiano', translationReady: true),
  nl('nl', 'Dutch', 'Nederlands', translationReady: true),
  pl('pl', 'Polish', 'Polski'),
  ru('ru', 'Russian', 'Русский', translationReady: true),
  uk('uk', 'Ukrainian', 'Українська'),
  ro('ro', 'Romanian', 'Română'),
  cs('cs', 'Czech', 'Čeština'),
  sk('sk', 'Slovak', 'Slovenčina'),
  hu('hu', 'Hungarian', 'Magyar'),
  bg('bg', 'Bulgarian', 'Български'),
  el('el', 'Greek', 'Ελληνικά'),
  ar('ar', 'Arabic', 'العربية', isRtl: true, translationReady: true),
  he('he', 'Hebrew', 'עברית', isRtl: true),
  fa('fa', 'Persian', 'فارسی', isRtl: true),
  hi('hi', 'Hindi', 'हिन्दी', translationReady: true),
  bn('bn', 'Bengali', 'বাংলা'),
  ur('ur', 'Urdu', 'اردو', isRtl: true),
  id('id', 'Indonesian', 'Bahasa Indonesia', translationReady: true),
  ms('ms', 'Malay', 'Bahasa Melayu'),
  th('th', 'Thai', 'ไทย'),
  vi('vi', 'Vietnamese', 'Tiếng Việt'),
  ja('ja', 'Japanese', '日本語'),
  ko('ko', 'Korean', '한국어'),
  zh('zh', 'Chinese', '中文'),
  sv('sv', 'Swedish', 'Svenska'),
  da('da', 'Danish', 'Dansk'),
  nb('nb', 'Norwegian', 'Norsk'),
  fi('fi', 'Finnish', 'Suomi'),
  sw('sw', 'Swahili', 'Kiswahili');

  const AppLanguage(
    this.code,
    this.englishName,
    this.nativeName, {
    this.isRtl = false,
    this.translationReady = false,
  });

  final String code;
  final String englishName;
  final String nativeName;
  final bool isRtl;
  final bool translationReady;

  Locale get locale => Locale(code);

  TextDirection get textDirection =>
      isRtl ? TextDirection.rtl : TextDirection.ltr;

  /// Maps a device locale tag onto a catalogued language.
  ///
  /// Regional variants collapse onto their base language (`pt-BR` → `pt`,
  /// `zh_Hans` → `zh`) and the legacy Norwegian tag `no` is normalised to
  /// `nb`, so device settings that name a region still resolve.
  static AppLanguage? fromCode(String? rawCode) {
    if (rawCode == null || rawCode.trim().isEmpty) return null;
    final normalized = rawCode
        .trim()
        .toLowerCase()
        .replaceAll('_', '-')
        .split('-')
        .first;
    final compatibleCode = normalized == 'no' ? 'nb' : normalized;
    for (final language in values) {
      if (language.code == compatibleCode) return language;
    }
    return null;
  }
}

const fallbackAppLanguage = AppLanguage.en;

/// Every locale Splixa plans to ship, translated or not.
final targetAppLanguages = AppLanguage.values.toList(growable: false);

/// Locales with a complete dictionary; these are the only ones offered in the
/// picker and the only ones auto-detection will select.
final supportedAppLanguages = AppLanguage.values
    .where((language) => language.translationReady)
    .toList(growable: false);
final supportedAppLocales = supportedAppLanguages
    .map((language) => language.locale)
    .toList(growable: false);

const _prefsKey = 'app_language';

/// Mirrors [appLanguageProvider] for services without a [WidgetRef].
AppLanguage currentAppLanguage = fallbackAppLanguage;

final appLanguageProvider =
    StateNotifierProvider<AppLanguageNotifier, AppLanguage>((ref) {
      return AppLanguageNotifier(fallbackAppLanguage);
    });

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier(AppLanguage initialLanguage) : super(initialLanguage) {
    _apply(initialLanguage);
  }

  /// Resolution order: a previously persisted choice, then the device's
  /// preferred locales in order, then English.
  static Future<AppLanguageNotifier> load({Iterable<Locale>? locales}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = AppLanguage.fromCode(preferences.getString(_prefsKey));
    if (saved?.translationReady ?? false) return AppLanguageNotifier(saved!);

    final systemLocales =
        locales ?? WidgetsBinding.instance.platformDispatcher.locales;
    for (final locale in systemLocales) {
      final detected = AppLanguage.fromCode(locale.languageCode);
      if (detected?.translationReady ?? false) {
        return AppLanguageNotifier(detected!);
      }
    }
    return AppLanguageNotifier(fallbackAppLanguage);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (state != language) {
      state = language;
      _apply(language);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_prefsKey, language.code);
  }

  void _apply(AppLanguage language) {
    currentAppLanguage = language;
    Intl.defaultLocale = language.code;
  }
}
