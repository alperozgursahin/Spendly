import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'revenuecat_config.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(_hasServerReviewAccess()) {
    _reviewAccess = state;
    _init();
  }

  bool _reviewAccess = false;

  static bool _hasServerReviewAccess() {
    return Supabase
            .instance
            .client
            .auth
            .currentUser
            ?.appMetadata['play_review'] ==
        true;
  }

  void grantReviewAccess() {
    _reviewAccess = true;
    if (mounted) state = true;
  }

  Future<void> _init() async {
    try {
      if (kIsWeb) return;

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _updatePremiumStatus(customerInfo);
      });

      final customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  void _updatePremiumStatus(CustomerInfo customerInfo) {
    if (RevenueCatConfig.premiumEntitlementId.isEmpty) return;

    final hasRevenueCatEntitlement =
        customerInfo
            .entitlements
            .all[RevenueCatConfig.premiumEntitlementId]
            ?.isActive ??
        false;
    final isPro = _reviewAccess || hasRevenueCatEntitlement;

    if (mounted && state != isPro) {
      state = isPro;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _updatePremiumStatus(purchaseResult.customerInfo);
      return state;
    } catch (e) {
      debugPrint("Purchase failed: $e");
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updatePremiumStatus(customerInfo);
      return state;
    } catch (e) {
      debugPrint("Restore failed: $e");
      return false;
    }
  }

  void reset() {
    _reviewAccess = false;
    state = false;
  }
}

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (e) {
    debugPrint("Failed to fetch offerings: $e");
    return null;
  }
});
