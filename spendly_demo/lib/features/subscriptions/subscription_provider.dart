import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false) {
    checkSubscription();
  }

  Future<void> checkSubscription() async {
    try {
      /*
      final customerInfo = await Purchases.getCustomerInfo();
      // 'pro' entitlements'ı kullanıyoruz. RevenueCat üzerinden "pro" isimli entitlement oluşturmalısınız.
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
      state = isPro;
      */
      state = false;
    } catch (e) {
      state = false;
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      /*
      final purchaseResult = await Purchases.purchasePackage(package);
      final isPro =
          purchaseResult.customerInfo.entitlements.all["pro"]?.isActive ??
          false;
      state = isPro;
      return isPro;
      */
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      /*
      final customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all["pro"]?.isActive ?? false;
      state = isPro;
      return isPro;
      */
      return false;
    } catch (e) {
      return false;
    }
  }
}

// Tüm available paketleri getiren provider
final offeringsProvider = FutureProvider<Offerings>((ref) async {
  // return await Purchases.getOfferings();
  throw Exception('Purchases pass is disabled for testing');
});
