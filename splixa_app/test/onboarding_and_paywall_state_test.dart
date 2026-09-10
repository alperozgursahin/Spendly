import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splixa_app/core/analytics_service.dart';
import 'package:splixa_app/features/onboarding/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingController', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('defaults to incomplete for a first-time user', () async {
      final controller = await OnboardingController.load();

      expect(controller.completed, isFalse);
    });

    test('persists completion for the next app launch', () async {
      final controller = await OnboardingController.load();

      await controller.complete();
      final reloadedController = await OnboardingController.load();

      expect(controller.completed, isTrue);
      expect(reloadedController.completed, isTrue);
    });

    test('reset removes completion after account deletion', () async {
      final controller = await OnboardingController.load();
      await controller.complete();

      await controller.reset();
      final reloadedController = await OnboardingController.load();

      expect(controller.completed, isFalse);
      expect(reloadedController.completed, isFalse);
    });
  });

  group('PaywallSource', () {
    test('round-trips every analytics source', () {
      for (final source in PaywallSource.values) {
        expect(PaywallSource.fromAnalyticsValue(source.analyticsValue), source);
      }
    });

    test('uses unknown for an unrecognized route value', () {
      expect(
        PaywallSource.fromAnalyticsValue('not-a-real-source'),
        PaywallSource.unknown,
      );
    });
  });
}
