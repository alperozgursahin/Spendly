import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/app_strings.dart';
import 'package:splixa_app/core/locale_provider.dart';

/// Phase 2 translation-key validator.
///
/// English is the source locale: it defines which keys exist. Every shipped
/// locale must cover all of them, with structurally identical placeholders and
/// no accidental leftovers. A failure here is a release blocker, not a warning.
void main() {
  const launchLocales = [
    AppLanguage.en,
    AppLanguage.tr,
    AppLanguage.es,
    AppLanguage.pt,
    AppLanguage.de,
    AppLanguage.fr,
    AppLanguage.it,
    AppLanguage.nl,
    AppLanguage.ru,
    AppLanguage.ar,
    AppLanguage.hi,
    AppLanguage.id,
  ];

  test('global locale catalog contains at least 30 unique languages', () {
    expect(targetAppLanguages.length, greaterThanOrEqualTo(30));
    expect(
      AppLanguage.values.map((language) => language.code).toSet(),
      hasLength(AppLanguage.values.length),
    );
  });

  test('only complete dictionaries are exposed in the production selector', () {
    expect(supportedAppLanguages, launchLocales);
    expect(supportedAppLanguages.first, fallbackAppLanguage);
    for (final language in supportedAppLanguages) {
      expect(
        AppStrings.catalog.containsKey(language),
        isTrue,
        reason: '${language.code} is marked ready but has no dictionary',
      );
    }
  });

  test('every localization key has a non-empty English source value', () {
    final missing = <String>[];
    for (final entry in AppStrings.source.entries) {
      if (entry.value.trim().isEmpty) missing.add(entry.key);
    }

    expect(missing, isEmpty, reason: 'Empty English source values: $missing');
  });

  test('every shipped locale covers every source key', () {
    final missing = <String>[];
    for (final language in supportedAppLanguages) {
      final dictionary = AppStrings.catalog[language]!;
      for (final key in AppStrings.source.keys) {
        final value = dictionary[key];
        if (value == null || value.trim().isEmpty) {
          missing.add('${language.code}:$key');
        }
      }
    }

    expect(missing, isEmpty, reason: 'Missing translations: $missing');
  });

  test('no shipped locale defines a key English does not', () {
    final unused = <String>[];
    for (final language in supportedAppLanguages) {
      for (final key in AppStrings.catalog[language]!.keys) {
        if (!AppStrings.source.containsKey(key)) {
          unused.add('${language.code}:$key');
        }
      }
    }

    expect(unused, isEmpty, reason: 'Orphaned keys: $unused');
  });

  test('every target locale resolves every source key through fallback', () {
    final unresolved = <String>[];
    for (final language in AppLanguage.values) {
      for (final key in AppStrings.source.keys) {
        final value = AppStrings.of(key, language);
        if (value.trim().isEmpty || value == key) {
          unresolved.add('${language.code}:$key');
        }
      }
    }

    expect(unresolved, isEmpty, reason: 'Unresolved localization keys');
  });

  test('placeholders stay structurally compatible across locales', () {
    final mismatches = <String>[];
    for (final language in supportedAppLanguages) {
      if (language == fallbackAppLanguage) continue;
      final dictionary = AppStrings.catalog[language]!;
      for (final entry in AppStrings.source.entries) {
        final translated = dictionary[entry.key];
        if (translated == null) continue;
        if (_placeholders(entry.value) != _placeholders(translated)) {
          mismatches.add('${language.code}:${entry.key}');
        }
      }
    }

    expect(mismatches, isEmpty, reason: 'Placeholder mismatches: $mismatches');
  });

  test('format substitutes every placeholder it is given', () {
    final rendered = AppStrings.format('home_welcome', AppLanguage.en, {
      'name': 'İlayda',
    });

    expect(rendered, 'Welcome, İlayda');
    expect(rendered.contains('{'), isFalse);
  });

  test('unknown keys degrade to the key rather than throwing', () {
    expect(
      AppStrings.of('definitely_not_a_key', AppLanguage.de),
      'definitely_not_a_key',
    );
  });

  test('right-to-left locales report an RTL text direction', () {
    expect(AppLanguage.ar.isRtl, isTrue);
    expect(AppLanguage.ar.textDirection, TextDirection.rtl);
    expect(AppLanguage.en.textDirection, TextDirection.ltr);
    expect(AppLanguage.tr.textDirection, TextDirection.ltr);

    // At least one RTL locale ships, so RTL layout is exercised at launch.
    expect(
      supportedAppLanguages.where((language) => language.isRtl),
      isNotEmpty,
    );
  });
}

String _placeholders(String value) {
  final tokens = RegExp(
    r'\{[^}]+\}|%s',
  ).allMatches(value).map((m) => m.group(0)!).toList()..sort();
  return tokens.join('|');
}
