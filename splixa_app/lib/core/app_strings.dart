import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/strings_ar.dart';
import 'l10n/strings_de.dart';
import 'l10n/strings_en.dart';
import 'l10n/strings_es.dart';
import 'l10n/strings_fr.dart';
import 'l10n/strings_hi.dart';
import 'l10n/strings_id.dart';
import 'l10n/strings_it.dart';
import 'l10n/strings_nl.dart';
import 'l10n/strings_pt.dart';
import 'l10n/strings_ru.dart';
import 'l10n/strings_tr.dart';
import 'locale_provider.dart';

/// Looks up [key] for the language currently held by [appLanguageProvider].
/// Every screen in this app is a Consumer/ConsumerState, so a [WidgetRef] is
/// always available where this is called.
String tr(WidgetRef ref, String key) {
  final language = ref.watch(appLanguageProvider);
  return AppStrings.of(key, language);
}

/// [tr] with `{placeholder}` substitution, e.g.
/// `trp(ref, 'home_welcome', {'name': userName})`.
String trp(WidgetRef ref, String key, Map<String, String> values) {
  final language = ref.watch(appLanguageProvider);
  return AppStrings.format(key, language, values);
}

/// Predefined category values are stored/compared in their canonical Turkish
/// form (see the `predefinedCategories` lists in dashboard/add-expense
/// screens); this only translates the label shown to the user. Custom
/// (user-typed) categories pass through unchanged.
const _categoryKeysByCategory = {
  'Market': 'category_market',
  'Yemek': 'category_food',
  'Ulaşım': 'category_transport',
  'Eğlence': 'category_entertainment',
  'Maaş': 'category_salary',
  'Aidat': 'category_dues',
  'Fatura': 'category_bill',
  'Diğer': 'category_other',
};

String categoryLabel(WidgetRef ref, String category) {
  final key = _categoryKeysByCategory[category];
  return key == null ? category : tr(ref, key);
}

/// Same as [categoryLabel] but for call sites (e.g. the PDF export service)
/// that only have an [AppLanguage] on hand rather than a [WidgetRef].
String categoryLabelForLanguage(AppLanguage language, String category) {
  final key = _categoryKeysByCategory[category];
  return key == null ? category : AppStrings.of(key, language);
}

/// The localization catalog.
///
/// English (`lib/core/l10n/strings_en.dart`) is the source of truth: it defines
/// which keys exist. Every other dictionary is looked up first and falls back
/// to English per key, so a locale can never render a blank or a raw key.
/// `test/localization_catalog_test.dart` enforces key parity and placeholder
/// compatibility across all shipped locales.
class AppStrings {
  const AppStrings._();

  static const Map<AppLanguage, Map<String, String>> catalog = {
    AppLanguage.en: enStrings,
    AppLanguage.tr: trStrings,
    AppLanguage.es: esStrings,
    AppLanguage.pt: ptStrings,
    AppLanguage.de: deStrings,
    AppLanguage.fr: frStrings,
    AppLanguage.it: itStrings,
    AppLanguage.nl: nlStrings,
    AppLanguage.ru: ruStrings,
    AppLanguage.ar: arStrings,
    AppLanguage.hi: hiStrings,
    AppLanguage.id: idStrings,
  };

  /// The complete set of keys the app may request, defined by English.
  static const Map<String, String> source = enStrings;

  static String of(String key, AppLanguage language) {
    final value = catalog[language]?[key];
    if (value != null && value.isNotEmpty) return value;
    return source[key] ?? key;
  }

  /// Replaces `{name}`-style placeholders in the resolved string.
  static String format(
    String key,
    AppLanguage language,
    Map<String, String> values,
  ) {
    var result = of(key, language);
    values.forEach((name, value) {
      result = result.replaceAll('{$name}', value);
    });
    return result;
  }
}
