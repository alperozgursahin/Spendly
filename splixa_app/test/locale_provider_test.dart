import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splixa_app/core/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('detects a production-ready system language on first launch', () async {
    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('tr', 'TR')],
    );

    expect(notifier.state, AppLanguage.tr);
    expect(currentAppLanguage, AppLanguage.tr);
  });

  test('matches a regional variant onto its base launch locale', () async {
    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('pt', 'BR')],
    );

    expect(notifier.state, AppLanguage.pt);
  });

  test('detects a right-to-left launch locale', () async {
    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('ar', 'EG')],
    );

    expect(notifier.state, AppLanguage.ar);
    expect(notifier.state.isRtl, isTrue);
  });

  test('does not expose an untranslated target locale', () async {
    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('sw', 'KE')],
    );

    expect(notifier.state, fallbackAppLanguage);
  });

  test('falls back to English for an unsupported system language', () async {
    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('is', 'IS')],
    );

    expect(notifier.state, fallbackAppLanguage);
  });

  test('walks the device locale list until a shipped locale matches', () async {
    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('is', 'IS'), Locale('sw'), Locale('de', 'AT')],
    );

    expect(notifier.state, AppLanguage.de);
  });

  test('persisted language takes precedence over the system locale', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language': 'es',
    });

    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('tr', 'TR')],
    );

    expect(notifier.state, AppLanguage.es);
  });

  test('a persisted but no longer shipped locale falls back', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'app_language': 'sw',
    });

    final notifier = await AppLanguageNotifier.load(
      locales: const [Locale('en', 'US')],
    );

    expect(notifier.state, fallbackAppLanguage);
  });

  test('normalizes regional and Norwegian locale codes', () {
    expect(AppLanguage.fromCode('pt-BR'), AppLanguage.pt);
    expect(AppLanguage.fromCode('zh_Hans'), AppLanguage.zh);
    expect(AppLanguage.fromCode('no'), AppLanguage.nb);
    expect(AppLanguage.fromCode('  ID  '), AppLanguage.id);
    expect(AppLanguage.fromCode(''), isNull);
    expect(AppLanguage.fromCode(null), isNull);
  });

  test('persists an explicit language selection', () async {
    final notifier = AppLanguageNotifier(AppLanguage.en);

    await notifier.setLanguage(AppLanguage.ar);
    final preferences = await SharedPreferences.getInstance();

    expect(notifier.state, AppLanguage.ar);
    expect(preferences.getString('app_language'), 'ar');
    expect(currentAppLanguage, AppLanguage.ar);

    // Live switching updates state without a restart.
    await notifier.setLanguage(AppLanguage.fr);
    expect(notifier.state, AppLanguage.fr);
    expect(currentAppLanguage, AppLanguage.fr);
  });

  test('supported locales feed MaterialApp.supportedLocales', () {
    expect(supportedAppLocales, hasLength(supportedAppLanguages.length));
    expect(supportedAppLocales.first, const Locale('en'));
    expect(supportedAppLocales, contains(const Locale('ar')));
  });
}
