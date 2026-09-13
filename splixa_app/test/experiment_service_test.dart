import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/core/experiment_service.dart';

void main() {
  test('onboarding variants accept known values and fail closed', () {
    expect(
      OnboardingExperimentVariant.parse('focused'),
      OnboardingExperimentVariant.focused,
    );
    expect(
      OnboardingExperimentVariant.parse('unexpected'),
      OnboardingExperimentVariant.control,
    );
  });

  test('paywall variants accept known values and fail closed', () {
    expect(
      PaywallExperimentVariant.parse('plans_first'),
      PaywallExperimentVariant.plansFirst,
    );
    expect(
      PaywallExperimentVariant.parse('unexpected'),
      PaywallExperimentVariant.control,
    );
  });
}
