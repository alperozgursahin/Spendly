import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'experiment_service.dart';

enum PaywallSource {
  onboarding('onboarding'),
  unlimitedGroups('unlimited_groups'),
  personalExpenseLimit('personal_expense_limit'),
  receiptScan('receipt_scan'),
  receiptAttachment('receipt_attachment'),
  customExchangeRate('custom_exchange_rate'),
  customCategories('custom_categories'),
  recurringExpenses('recurring_expenses'),
  debtReminders('debt_reminders'),
  biometricLock('biometric_lock'),
  homeWidget('home_widget'),
  advancedAnalytics('advanced_analytics'),
  advancedReports('advanced_reports'),
  tripSummary('trip_summary'),
  profile('profile'),
  unknown('unknown');

  const PaywallSource(this.analyticsValue);

  final String analyticsValue;

  static PaywallSource fromAnalyticsValue(String? value) {
    return PaywallSource.values.firstWhere(
      (source) => source.analyticsValue == value,
      orElse: () => PaywallSource.unknown,
    );
  }
}

enum AnalyticsLoginMethod {
  google('google'),
  password('password');

  const AnalyticsLoginMethod(this.analyticsValue);

  final String analyticsValue;
}

enum ExpenseAnalyticsScope {
  personal('personal'),
  group('group');

  const ExpenseAnalyticsScope(this.analyticsValue);

  final String analyticsValue;
}

enum AnalyticsPurchaseOutcome {
  cancelled('cancelled'),
  failed('failed');

  const AnalyticsPurchaseOutcome(this.analyticsValue);

  final String analyticsValue;
}

enum LedgerAnalyticsAction {
  acknowledged('acknowledged'),
  paymentSent('payment_sent'),
  paymentConfirmed('payment_confirmed'),
  rejected('rejected'),
  archived('archived');

  const LedgerAnalyticsAction(this.analyticsValue);

  final String analyticsValue;
}

typedef AnalyticsEventWriter =
    Future<void> Function(String name, Map<String, Object>? parameters);

/// One fault-tolerant gateway for product analytics.
///
/// Firebase configuration stays outside source control. Android reads the
/// generated resources from `google-services.json`; other targets can use the
/// environment fallback. Missing configuration never blocks app startup.
class AnalyticsService {
  AnalyticsService._() : _eventWriter = null;

  @visibleForTesting
  AnalyticsService.forTesting(AnalyticsEventWriter eventWriter)
    : _eventWriter = eventWriter,
      _isEnabled = true;

  static final AnalyticsService instance = AnalyticsService._();

  final AnalyticsEventWriter? _eventWriter;
  FirebaseAnalytics? _analytics;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  FirebaseAnalyticsObserver? get navigationObserver {
    final analytics = _analytics;
    return analytics == null
        ? null
        : FirebaseAnalyticsObserver(analytics: analytics);
  }

  Future<void> initialize() async {
    if (!_supportsAnalytics) return;

    try {
      if (Firebase.apps.isEmpty) {
        final options = _firebaseOptionsFromEnvironment();
        if (options == null) {
          await Firebase.initializeApp();
        } else {
          await Firebase.initializeApp(options: options);
        }
      }
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      _isEnabled = true;
    } catch (error) {
      _isEnabled = false;
      debugPrint(
        'Firebase Analytics disabled until platform configuration is added: '
        '$error',
      );
    }
  }

  Future<void> setExperimentContext({
    required OnboardingExperimentVariant onboardingVariant,
    required PaywallExperimentVariant paywallVariant,
  }) async {
    await Future.wait([
      _setUserProperty(
        name: 'onboarding_variant',
        value: onboardingVariant.analyticsValue,
      ),
      _setUserProperty(
        name: 'paywall_variant',
        value: paywallVariant.analyticsValue,
      ),
    ]);
  }

  Future<void> setAppLanguage(String languageCode) {
    return _setUserProperty(name: 'app_language', value: languageCode);
  }

  Future<void> setSubscriptionTier({required bool isPro}) {
    return _setUserProperty(
      name: 'subscription_tier',
      value: isPro ? 'pro' : 'free',
    );
  }

  Future<void> identifyUser(String? userId) async {
    final analytics = _analytics;
    if (!_isEnabled || analytics == null) return;
    try {
      await analytics.setUserId(id: userId);
    } catch (error) {
      debugPrint('Analytics user identity update failed: $error');
    }
  }

  Future<void> onboardingStart({
    required OnboardingExperimentVariant variant,
    required int totalSteps,
  }) {
    return _log(
      'onboarding_start',
      parameters: {
        'variant': variant.analyticsValue,
        'total_steps': totalSteps,
      },
    );
  }

  Future<void> onboardingStepViewed({
    required int step,
    required String stepName,
    required OnboardingExperimentVariant variant,
    required int totalSteps,
  }) {
    return _log(
      'onboarding_step_viewed',
      parameters: {
        'step': step,
        'step_name': stepName,
        'variant': variant.analyticsValue,
        'total_steps': totalSteps,
      },
    );
  }

  Future<void> onboardingComplete({
    required String completionMethod,
    required OnboardingExperimentVariant variant,
    required int totalSteps,
    required int durationMilliseconds,
  }) {
    return _log(
      'onboarding_complete',
      parameters: {
        'completion_method': completionMethod,
        'variant': variant.analyticsValue,
        'total_steps': totalSteps,
        'duration_ms': durationMilliseconds,
      },
    );
  }

  Future<void> onboardingInterrupted({
    required int step,
    required int totalSteps,
    required OnboardingExperimentVariant variant,
    required int durationMilliseconds,
  }) {
    return _log(
      'onboarding_interrupted',
      parameters: {
        'step': step,
        'total_steps': totalSteps,
        'variant': variant.analyticsValue,
        'duration_ms': durationMilliseconds,
      },
    );
  }

  /// Firebase automatically records `app_open` when Analytics collection is
  /// enabled. Splixa deliberately does not emit a second manual event because
  /// that would double-count launches.
  Future<void> login({required AnalyticsLoginMethod method}) {
    return _log('login', parameters: {'method': method.analyticsValue});
  }

  Future<void> signUp({required AnalyticsLoginMethod method}) {
    return _log('sign_up', parameters: {'method': method.analyticsValue});
  }

  Future<void> profileSetupComplete({required String source}) {
    return _log('profile_setup_complete', parameters: {'source': source});
  }

  Future<void> loginAttempt({required AnalyticsLoginMethod method}) {
    return _log('login_attempt', parameters: {'method': method.analyticsValue});
  }

  Future<void> loginFailed({
    required AnalyticsLoginMethod method,
    required String reasonCode,
  }) {
    return _log(
      'login_failed',
      parameters: {'method': method.analyticsValue, 'reason_code': reasonCode},
    );
  }

  Future<void> paywallView({required PaywallSource source}) {
    return _log(
      'paywall_view',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
      },
    );
  }

  Future<void> paywallPackageSelected({
    required PaywallSource source,
    required String packageId,
    required String productId,
  }) {
    return _log(
      'paywall_package_selected',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
        'package_id': packageId,
        'product_id': productId,
      },
    );
  }

  Future<void> paywallDismissed({
    required PaywallSource source,
    required bool purchaseCompleted,
    required int durationMilliseconds,
  }) {
    return _log(
      'paywall_dismissed',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
        'purchase_completed': purchaseCompleted ? 1 : 0,
        'duration_ms': durationMilliseconds,
      },
    );
  }

  Future<void> purchaseAttempt({
    required PaywallSource source,
    required String packageId,
    required String productId,
  }) {
    return _log(
      'purchase_attempt',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
        'package_id': packageId,
        'product_id': productId,
      },
    );
  }

  Future<void> purchaseSuccess({
    required PaywallSource source,
    required String packageId,
    required String productId,
    required String currencyCode,
    required double price,
  }) {
    return _log(
      'purchase_success',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
        'package_id': packageId,
        'product_id': productId,
        'currency': currencyCode,
        'value': price,
      },
    );
  }

  Future<void> purchaseEnded({
    required PaywallSource source,
    required String packageId,
    required String productId,
    required AnalyticsPurchaseOutcome outcome,
  }) {
    return _log(
      'purchase_ended',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
        'package_id': packageId,
        'product_id': productId,
        'outcome': outcome.analyticsValue,
      },
    );
  }

  Future<void> subscriptionStarted({
    required PaywallSource source,
    required String packageId,
    required String productId,
  }) {
    return _log(
      'subscription_started',
      parameters: {
        'source': source.analyticsValue,
        'variant': ExperimentService.instance.paywallVariant.analyticsValue,
        'package_id': packageId,
        'product_id': productId,
      },
    );
  }

  Future<void> expenseAdded({required ExpenseAnalyticsScope scope}) {
    return _log('expense_added', parameters: {'scope': scope.analyticsValue});
  }

  Future<void> groupCreated() => _log('group_created');

  Future<void> proLimitReached({required String limit}) {
    return _log('pro_limit_reached', parameters: {'limit': limit});
  }

  Future<void> proFeatureSelected({required String feature}) {
    return _log('pro_feature_selected', parameters: {'feature': feature});
  }

  Future<void> proFeatureCompleted({required String feature}) {
    return _log('pro_feature_completed', parameters: {'feature': feature});
  }

  Future<void> ledgerActionCompleted({required LedgerAnalyticsAction action}) {
    return _log(
      'ledger_action_completed',
      parameters: {'action': action.analyticsValue},
    );
  }

  Future<void> _log(String eventName, {Map<String, Object>? parameters}) async {
    final eventWriter = _eventWriter;
    if (eventWriter != null) {
      await eventWriter(eventName, parameters);
      return;
    }

    final analytics = _analytics;
    if (!_isEnabled || analytics == null) return;

    try {
      await analytics.logEvent(name: eventName, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics event $eventName failed: $error');
    }
  }

  Future<void> _setUserProperty({
    required String name,
    required String? value,
  }) async {
    final analytics = _analytics;
    if (!_isEnabled || analytics == null) return;
    try {
      await analytics.setUserProperty(name: name, value: value);
    } catch (error) {
      debugPrint('Analytics user property $name failed: $error');
    }
  }

  bool get _supportsAnalytics {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  FirebaseOptions? _firebaseOptionsFromEnvironment() {
    final apiKey = dotenv.env['FIREBASE_API_KEY']?.trim();
    final projectId = dotenv.env['FIREBASE_PROJECT_ID']?.trim();
    final senderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID']?.trim();
    final appIdKey = kIsWeb
        ? 'FIREBASE_WEB_APP_ID'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'FIREBASE_ANDROID_APP_ID',
            TargetPlatform.iOS => 'FIREBASE_IOS_APP_ID',
            TargetPlatform.macOS => 'FIREBASE_MACOS_APP_ID',
            _ => 'FIREBASE_WEB_APP_ID',
          };
    final appId = dotenv.env[appIdKey]?.trim();

    if (apiKey == null ||
        apiKey.isEmpty ||
        projectId == null ||
        projectId.isEmpty ||
        senderId == null ||
        senderId.isEmpty ||
        appId == null ||
        appId.isEmpty) {
      return null;
    }

    String? optional(String key) {
      final value = dotenv.env[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      authDomain: optional('FIREBASE_AUTH_DOMAIN'),
      storageBucket: optional('FIREBASE_STORAGE_BUCKET'),
      measurementId: optional('FIREBASE_MEASUREMENT_ID'),
      iosBundleId: optional('FIREBASE_IOS_BUNDLE_ID'),
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
