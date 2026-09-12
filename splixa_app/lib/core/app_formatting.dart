import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app_strings.dart';
import 'locale_provider.dart';

/// Locale-aware number, currency, date and relative-time formatting.
///
/// Every user-visible number and date goes through here so a locale's own
/// grouping separator, decimal mark, digit shapes and date order are used.
/// [AppLanguageNotifier] keeps `Intl.defaultLocale` in sync, but each helper
/// takes an explicit language so services without a `WidgetRef` stay correct.
class AppFormat {
  const AppFormat._();

  static bool _initialized = false;

  /// Loads `intl` date symbols for every locale.
  ///
  /// `GlobalMaterialLocalizations` only initializes the locale it loads, so
  /// formatting a date for any other language (a PDF export, a background
  /// notification, a unit test) would throw `LocaleDataException`. Call this
  /// once during startup and in test setup; repeat calls are cheap no-ops.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await initializeDateFormatting();
    _initialized = true;
  }

  /// A plain decimal amount: `1.234,56` in tr/de, `1,234.56` in en.
  static String amount(num value, [AppLanguage? language]) {
    final locale = (language ?? currentAppLanguage).code;
    return NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(value);
  }

  /// An amount next to a currency symbol the user picked. The symbol is never
  /// reconstructed from the locale — store/user currency stays authoritative,
  /// only the number formatting follows the locale.
  static String amountWithSymbol(
    num value,
    String symbol, [
    AppLanguage? language,
  ]) {
    final lang = language ?? currentAppLanguage;
    return lang.isRtl
        ? '${amount(value, lang)} $symbol'
        : '$symbol${amount(value, lang)}';
  }

  /// Whole-number counts (members, activities) in the locale's digits.
  static String count(num value, [AppLanguage? language]) {
    final locale = (language ?? currentAppLanguage).code;
    return NumberFormat.decimalPattern(locale).format(value);
  }

  /// Short numeric date, ordered the way the locale writes it.
  static String shortDate(DateTime date, [AppLanguage? language]) {
    final locale = (language ?? currentAppLanguage).code;
    return DateFormat.yMd(locale).format(date);
  }

  /// Day + month, for list rows and chart axes.
  static String dayMonth(DateTime date, [AppLanguage? language]) {
    final locale = (language ?? currentAppLanguage).code;
    return DateFormat.MMMd(locale).format(date);
  }

  /// Month + year, used by the monthly report header.
  static String monthYear(DateTime date, [AppLanguage? language]) {
    final locale = (language ?? currentAppLanguage).code;
    return DateFormat.yMMMM(locale).format(date);
  }

  static String dateTime(DateTime date, [AppLanguage? language]) {
    final locale = (language ?? currentAppLanguage).code;
    return '${DateFormat.yMd(locale).format(date)} '
        '${DateFormat.Hm(locale).format(date)}';
  }

  /// "Just now" / "5 min ago" / a short date once it is older than a week.
  static String relative(
    DateTime date, {
    AppLanguage? language,
    DateTime? now,
  }) {
    final lang = language ?? currentAppLanguage;
    final difference = (now ?? DateTime.now()).difference(date);

    if (difference.inMinutes < 1) return AppStrings.of('time_just_now', lang);
    if (difference.inHours < 1) {
      return AppStrings.format('time_minutes_ago', lang, {
        'count': count(difference.inMinutes, lang),
      });
    }
    if (difference.inDays < 1) {
      return AppStrings.format('time_hours_ago', lang, {
        'count': count(difference.inHours, lang),
      });
    }
    if (difference.inDays < 7) {
      return AppStrings.format('time_days_ago', lang, {
        'count': count(difference.inDays, lang),
      });
    }
    return shortDate(date, lang);
  }
}
