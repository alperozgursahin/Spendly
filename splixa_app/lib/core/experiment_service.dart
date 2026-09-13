import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

enum OnboardingExperimentVariant {
  control('control'),
  focused('focused');

  const OnboardingExperimentVariant(this.analyticsValue);

  final String analyticsValue;

  static OnboardingExperimentVariant parse(String raw) {
    return values.firstWhere(
      (variant) => variant.analyticsValue == raw.trim().toLowerCase(),
      orElse: () => control,
    );
  }
}

enum PaywallExperimentVariant {
  control('control'),
  plansFirst('plans_first');

  const PaywallExperimentVariant(this.analyticsValue);

  final String analyticsValue;

  static PaywallExperimentVariant parse(String raw) {
    return values.firstWhere(
      (variant) => variant.analyticsValue == raw.trim().toLowerCase(),
      orElse: () => control,
    );
  }
}

/// Stable, fail-safe access to remotely assigned product experiment variants.
///
/// Previously activated values are read synchronously for the current launch.
/// A background refresh prepares assignments for the next launch, so an
/// onboarding flow can never change page count while the user is inside it.
class ExperimentService {
  ExperimentService._();

  static final ExperimentService instance = ExperimentService._();

  static const onboardingVariantKey = 'onboarding_flow_variant';
  static const paywallVariantKey = 'paywall_layout_variant';

  OnboardingExperimentVariant _onboardingVariant =
      OnboardingExperimentVariant.control;
  PaywallExperimentVariant _paywallVariant = PaywallExperimentVariant.control;
  bool _initialized = false;

  OnboardingExperimentVariant get onboardingVariant => _onboardingVariant;
  PaywallExperimentVariant get paywallVariant => _paywallVariant;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized || Firebase.apps.isEmpty) return;

    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setDefaults(const <String, Object>{
        onboardingVariantKey: 'control',
        paywallVariantKey: 'control',
      });
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );

      _readActiveValues(remoteConfig);

      // Give a first install a small budget to receive its A/B assignment
      // before the activation event. Offline/slow launches immediately retain
      // cached or default values, while the same fetch prepares the next run.
      final refresh = _refresh(remoteConfig);
      try {
        await refresh.timeout(const Duration(seconds: 2));
      } on TimeoutException {
        unawaited(refresh);
      }
      _initialized = true;
    } catch (error) {
      _initialized = true;
      debugPrint('Remote Config defaults active; refresh unavailable: $error');
    }
  }

  Future<void> _refresh(FirebaseRemoteConfig remoteConfig) async {
    try {
      await remoteConfig.fetchAndActivate();
      _readActiveValues(remoteConfig);
    } catch (error) {
      debugPrint('Remote Config refresh deferred: $error');
    }
  }

  void _readActiveValues(FirebaseRemoteConfig remoteConfig) {
    _onboardingVariant = OnboardingExperimentVariant.parse(
      remoteConfig.getString(onboardingVariantKey),
    );
    _paywallVariant = PaywallExperimentVariant.parse(
      remoteConfig.getString(paywallVariantKey),
    );
  }
}
