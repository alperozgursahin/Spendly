import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'revenuecat_config.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    _init();
  }

  Future<void> _init() async {
    try {
      if (kIsWeb) return; // RevenueCat web desteklemiyor

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

    final isPro =
        customerInfo
            .entitlements
            .all[RevenueCatConfig.premiumEntitlementId]
            ?.isActive ??
        false;

    if (mounted && state != isPro) {
      state = isPro;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
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
}

final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  try {
    return await Purchases.getOfferings();
  } catch (e) {
    debugPrint("Failed to fetch offerings: $e");
    return null;
  }
});
