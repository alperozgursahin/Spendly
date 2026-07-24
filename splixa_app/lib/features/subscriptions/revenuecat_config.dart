import 'package:flutter_dotenv/flutter_dotenv.dart';

class RevenueCatConfig {
  static String get apiKeyAndroid =>
      dotenv.env['REVENUECAT_ANDROID_PUBLIC_SDK_KEY'] ?? '';

  static String get apiKeyIOS =>
      dotenv.env['REVENUECAT_IOS_PUBLIC_SDK_KEY'] ?? '';

  static String get premiumEntitlementId =>
      dotenv.env['REVENUECAT_PREMIUM_ENTITLEMENT_ID'] ?? 'pro';
}
