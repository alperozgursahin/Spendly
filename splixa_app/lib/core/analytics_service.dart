import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum PaywallSource {
  onboarding('onboarding'),
  unlimitedGroups('unlimited_groups'),
  receiptScan('receipt_scan'),
  customExchangeRate('custom_exchange_rate'),
  advancedAnalytics('advanced_analytics'),
  advancedReports('advanced_reports'),
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

/// One fault-tolerant gateway for product analytics.
///
/// Firebase configuration is intentionally external to source control. Until
/// `flutterfire configure` supplies the platform configuration, every method
/// safely becomes a no-op instead of blocking app startup.
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

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

  Future<void> onboardingStart() => _log('onboarding_start');

  Future<void> onboardingStepViewed({
    required int step,
    required String stepName,
  }) {
    return _log(
      'onboarding_step_viewed',
      parameters: {'step': step, 'step_name': stepName},
    );
  }

  Future<void> onboardingComplete({required String completionMethod}) {
    return _log(
      'onboarding_complete',
      parameters: {'completion_method': completionMethod},
    );
  }

  Future<void> paywallView({required PaywallSource source}) {
    return _log('paywall_view', parameters: {'source': source.analyticsValue});
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
        'package_id': packageId,
        'product_id': productId,
        'currency': currencyCode,
        'value': price,
      },
    );
  }

  Future<void> _log(String eventName, {Map<String, Object>? parameters}) async {
    final analytics = _analytics;
    if (!_isEnabled || analytics == null) return;

    try {
      await analytics.logEvent(name: eventName, parameters: parameters);
    } catch (error) {
      debugPrint('Analytics event $eventName failed: $error');
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
