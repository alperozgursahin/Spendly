import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/analytics_service.dart';
import 'package:splixa_app/core/experiment_service.dart';

void main() {
  late List<({String name, Map<String, Object>? parameters})> events;
  late AnalyticsService analytics;

  setUp(() {
    events = [];
    analytics = AnalyticsService.forTesting((name, parameters) async {
      events.add((name: name, parameters: parameters));
    });
  });

  test('login uses the recommended event name and a non-PII method', () async {
    await analytics.login(method: AnalyticsLoginMethod.google);

    expect(events, hasLength(1));
    expect(events.single.name, 'login');
    expect(events.single.parameters, {'method': 'google'});
  });

  test('paywall view includes a normalized source', () async {
    await analytics.paywallView(source: PaywallSource.receiptScan);

    expect(events.single.name, 'paywall_view');
    expect(events.single.parameters, {
      'source': 'receipt_scan',
      'variant': 'control',
    });
  });

  test(
    'subscription start includes product context without user data',
    () async {
      await analytics.subscriptionStarted(
        source: PaywallSource.profile,
        packageId: r'$rc_annual',
        productId: 'splixa_pro_annual',
      );

      expect(events.single.name, 'subscription_started');
      expect(events.single.parameters, {
        'source': 'profile',
        'variant': 'control',
        'package_id': r'$rc_annual',
        'product_id': 'splixa_pro_annual',
      });
    },
  );

  test('expense added records scope but no financial payload', () async {
    await analytics.expenseAdded(scope: ExpenseAnalyticsScope.group);

    expect(events.single.name, 'expense_added');
    expect(events.single.parameters, {'scope': 'group'});
    expect(events.single.parameters, isNot(contains('amount')));
    expect(events.single.parameters, isNot(contains('currency')));
    expect(events.single.parameters, isNot(contains('category')));
  });

  test('onboarding funnel carries a stable experiment assignment', () async {
    await analytics.onboardingStart(
      variant: OnboardingExperimentVariant.focused,
      totalSteps: 3,
    );
    await analytics.onboardingStepViewed(
      step: 2,
      stepName: 'clear_group_splits',
      variant: OnboardingExperimentVariant.focused,
      totalSteps: 3,
    );
    await analytics.onboardingComplete(
      completionMethod: 'completed',
      variant: OnboardingExperimentVariant.focused,
      totalSteps: 3,
      durationMilliseconds: 4200,
    );

    expect(events.map((event) => event.name), [
      'onboarding_start',
      'onboarding_step_viewed',
      'onboarding_complete',
    ]);
    for (final event in events) {
      expect(event.parameters, containsPair('variant', 'focused'));
      expect(event.parameters, containsPair('total_steps', 3));
    }
  });

  test('failed login stores only a normalized reason code', () async {
    await analytics.loginFailed(
      method: AnalyticsLoginMethod.google,
      reasonCode: 'cancelled',
    );

    expect(events.single.name, 'login_failed');
    expect(events.single.parameters, {
      'method': 'google',
      'reason_code': 'cancelled',
    });
  });
}
