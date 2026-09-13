import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/analytics_service.dart';
import 'package:splixa_app/core/app_strings.dart';
import 'package:splixa_app/core/locale_provider.dart';
import 'package:splixa_app/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('four-step onboarding fits a small device in a long locale', (
    tester,
  ) async {
    await _setSurface(tester, const Size(320, 568));
    await _pumpOnboarding(tester, AppLanguage.de, Brightness.light);

    for (var page = 0; page < 4; page++) {
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: 'overflow on page $page');
      if (page < 3) {
        await tester.tap(
          find.text(AppStrings.of('onboarding_continue', AppLanguage.de)),
        );
        // Start the page animation on one frame, then advance beyond its
        // 360 ms duration. pumpAndSettle cannot be used because Lottie loops.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
    }

    expect(
      find.text(AppStrings.of('onboarding_start_free', AppLanguage.de)),
      findsOneWidget,
    );
  });

  testWidgets('Arabic onboarding is RTL, dark, and reduced-motion safe', (
    tester,
  ) async {
    await _setSurface(tester, const Size(430, 932));
    await _pumpOnboarding(
      tester,
      AppLanguage.ar,
      Brightness.dark,
      disableAnimations: true,
    );
    await tester.pump(const Duration(milliseconds: 300));

    final title = find.text(
      AppStrings.of('onboarding_p1_title', AppLanguage.ar),
    );
    expect(title, findsOneWidget);
    expect(Directionality.of(tester.element(title)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpOnboarding(
  WidgetTester tester,
  AppLanguage language,
  Brightness brightness, {
  bool disableAnimations = false,
}) async {
  final analytics = AnalyticsService.forTesting((_, __) async {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appLanguageProvider.overrideWith(
          (ref) => AppLanguageNotifier(language),
        ),
        onboardingControllerProvider.overrideWith(
          (ref) => OnboardingController(completed: false),
        ),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
      child: MaterialApp(
        locale: language.locale,
        supportedLocales: supportedAppLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorSchemeSeed: const Color(0xFF0E7490),
        ),
        builder: (context, child) {
          final data = MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations);
          return MediaQuery(data: data, child: child!);
        },
        home: const OnboardingScreen(),
      ),
    ),
  );
}
