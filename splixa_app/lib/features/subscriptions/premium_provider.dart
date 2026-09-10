import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/analytics_service.dart';
import 'revenuecat_config.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});

final customerInfoProvider = StateProvider<CustomerInfo?>((ref) => null);

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier(this._ref) : super(_hasServerReviewAccess()) {
    _reviewAccess = state;
    _customerInfoListener = _updatePremiumStatus;
    _init();
  }

  final Ref _ref;
  late final CustomerInfoUpdateListener _customerInfoListener;
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

      Purchases.addCustomerInfoUpdateListener(_customerInfoListener);

      final customerInfo = await Purchases.getCustomerInfo();
      _updatePremiumStatus(customerInfo);
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  void _updatePremiumStatus(CustomerInfo customerInfo) {
    _ref.read(customerInfoProvider.notifier).state = customerInfo;
    if (RevenueCatConfig.premiumEntitlementId.isEmpty) return;

    final hasRevenueCatEntitlement = _hasActiveEntitlement(customerInfo);
    final isPro = _reviewAccess || hasRevenueCatEntitlement;

    if (mounted && state != isPro) {
      state = isPro;
    }
  }

  Future<bool> purchasePackage(
    Package package, {
    required PaywallSource source,
  }) async {
    final analytics = _ref.read(analyticsServiceProvider);
    await analytics.purchaseAttempt(
      source: source,
      packageId: package.identifier,
      productId: package.storeProduct.identifier,
    );

    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      _updatePremiumStatus(purchaseResult.customerInfo);
      if (_hasActiveEntitlement(purchaseResult.customerInfo)) {
        await analytics.purchaseSuccess(
          source: source,
          packageId: package.identifier,
          productId: package.storeProduct.identifier,
          currencyCode: package.storeProduct.currencyCode,
          price: package.storeProduct.price,
        );
      }
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
    _ref.read(customerInfoProvider.notifier).state = null;
    state = false;
  }

  bool _hasActiveEntitlement(CustomerInfo customerInfo) {
    final entitlementId = RevenueCatConfig.premiumEntitlementId;
    if (entitlementId.isEmpty) return false;
    return customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      Purchases.removeCustomerInfoUpdateListener(_customerInfoListener);
    }
    super.dispose();
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
