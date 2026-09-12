import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/app_formatting.dart';
import 'package:splixa_app/core/locale_provider.dart';

/// Numbers, dates and relative time must follow the active locale rather than
/// one hardcoded Turkish/English format.
///
/// Assertions describe the *shape* the locale requires rather than an exact
/// CLDR string, so a future `intl` data update cannot fail the build for a
/// cosmetic change while still catching a genuine loss of localization.
void main() {
  final moment = DateTime(2026, 3, 9, 14, 30);

  // DateFormat needs locale data for any language other than the one
  // GlobalMaterialLocalizations loads, which a unit test never loads at all.
  setUpAll(() => AppFormat.ensureInitialized());

  test('decimal and grouping separators follow the locale', () {
    // English: comma groups, dot decimals.
    expect(AppFormat.amount(1234.5, AppLanguage.en), '1,234.50');

    // German and Turkish invert both separators.
    expect(AppFormat.amount(1234.5, AppLanguage.de), '1.234,50');
    expect(AppFormat.amount(1234.5, AppLanguage.tr), '1.234,50');

    // French and Russian group with a space and use a decimal comma.
    for (final language in [AppLanguage.fr, AppLanguage.ru]) {
      final formatted = AppFormat.amount(1234.5, language);
      expect(formatted, endsWith(',50'), reason: language.code);
      expect(formatted, startsWith('1'), reason: language.code);
      expect(formatted.contains('234'), isTrue, reason: language.code);
    }

    expect(AppFormat.amount(0, AppLanguage.en), '0.00');
  });

  test('currency symbol comes from the caller, never from the locale', () {
    expect(AppFormat.amountWithSymbol(10, r'$', AppLanguage.en), r'$10.00');
    expect(AppFormat.amountWithSymbol(10, '€', AppLanguage.de), '€10,00');

    // RTL locales place the symbol after the amount.
    expect(AppFormat.amountWithSymbol(10, '₺', AppLanguage.ar), endsWith('₺'));
  });

  test('short dates use the order the locale writes', () {
    final english = AppFormat.shortDate(moment, AppLanguage.en);
    final german = AppFormat.shortDate(moment, AppLanguage.de);

    expect(english, contains('2026'));
    expect(german, contains('2026'));

    // Month-first in English, day-first in German.
    expect(english.startsWith('3'), isTrue, reason: english);
    expect(german.startsWith('9'), isTrue, reason: german);
    expect(english == german, isFalse);
  });

  test('month/year headers are translated, not numeric', () {
    expect(AppFormat.monthYear(moment, AppLanguage.en), contains('2026'));
    expect(
      AppFormat.monthYear(moment, AppLanguage.en).toLowerCase(),
      contains('march'),
    );
    expect(
      AppFormat.monthYear(moment, AppLanguage.tr).toLowerCase(),
      contains('mart'),
    );
    expect(
      AppFormat.monthYear(moment, AppLanguage.de),
      isNot(AppFormat.monthYear(moment, AppLanguage.en)),
    );
  });

  test('relative time uses translated buckets', () {
    final now = DateTime(2026, 3, 9, 15, 0);

    expect(
      AppFormat.relative(
        now.subtract(const Duration(seconds: 20)),
        language: AppLanguage.en,
        now: now,
      ),
      'Just now',
    );
    expect(
      AppFormat.relative(
        now.subtract(const Duration(minutes: 5)),
        language: AppLanguage.en,
        now: now,
      ),
      '5 min ago',
    );
    expect(
      AppFormat.relative(
        now.subtract(const Duration(hours: 3)),
        language: AppLanguage.tr,
        now: now,
      ),
      '3 sa önce',
    );
    expect(
      AppFormat.relative(
        now.subtract(const Duration(days: 3)),
        language: AppLanguage.es,
        now: now,
      ),
      'hace 3 d',
    );
  });

  test('relative time degrades to a locale date beyond a week', () {
    final now = DateTime(2026, 3, 9, 15, 0);
    final old = DateTime(2026, 1, 2);

    expect(
      AppFormat.relative(old, language: AppLanguage.en, now: now),
      AppFormat.shortDate(old, AppLanguage.en),
    );
  });

  test('counts render without decimals', () {
    expect(AppFormat.count(5, AppLanguage.en), '5');
    expect(AppFormat.count(12, AppLanguage.tr), '12');
  });
}
