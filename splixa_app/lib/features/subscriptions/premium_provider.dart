import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/analytics_service.dart';
import 'revenuecat_config.dart';

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});

final customerInfoProvider = StateProvider<CustomerInfo?>((ref) => null);

/// Binds RevenueCat ownership to the authenticated Supabase user.
Future<CustomerInfo> synchronizeRevenueCatIdentity(User user) async {
  final result = await Purchases.logIn(user.id);
  final email = user.email?.trim();
  if (email != null && email.isNotEmpty) {
    await Purchases.setEmail(email);
  }
  return result.customerInfo;
}

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier(this._ref) : super(_hasServerReviewAccess()) {
    _reviewAccess = state;
    _customerInfoListener = _updatePremiumStatus;
    _init();
  }

  final Ref _ref;
  late final CustomerInfoUpdateListener _customerInfoListener;
  bool _reviewAccess = false;
  String? _identifiedUserId;
  String? _identitySyncUserId;
  Future<void>? _identitySyncFuture;

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

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        final customerInfo = await Purchases.getCustomerInfo();
        _updatePremiumStatus(customerInfo);
      } else {
        await identifyUser(user);
      }
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    }
  }

  Future<void> identifyUser(User user) {
    if (_identifiedUserId == user.id) return Future<void>.value();
    if (_identitySyncUserId == user.id && _identitySyncFuture != null) {
      return _identitySyncFuture!;
    }

    final operation = _synchronizeIdentity(user);
    _identitySyncUserId = user.id;
    _identitySyncFuture = operation;
    return operation.whenComplete(() {
      if (_identitySyncUserId == user.id) {
        _identitySyncUserId = null;
        _identitySyncFuture = null;
      }
    });
  }

  Future<void> _synchronizeIdentity(User user) async {
    if (kIsWeb || !await Purchases.isConfigured) return;

    final currentRevenueCatUserId = await Purchases.appUserID;
    final customerInfo = currentRevenueCatUserId == user.id
        ? await Purchases.getCustomerInfo()
        : await synchronizeRevenueCatIdentity(user);

    // A restored app session may already be identified from bootstrap. Keep
    // the email attribute synchronized even when another logIn is unnecessary.
    final email = user.email?.trim();
    if (currentRevenueCatUserId == user.id &&
        email != null &&
        email.isNotEmpty) {
      await Purchases.setEmail(email);
    }

    _identifiedUserId = user.id;
    _updatePremiumStatus(customerInfo);
    _ref.invalidate(offeringsProvider);
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
    final previousCustomerInfo = _ref.read(customerInfoProvider);
    final previouslyActive =
        previousCustomerInfo != null &&
        _hasActiveEntitlement(previousCustomerInfo);
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
        if (!previouslyActive &&
            package.storeProduct.productCategory ==
                ProductCategory.subscription) {
          await analytics.subscriptionStarted(
            source: source,
            packageId: package.identifier,
            productId: package.storeProduct.identifier,
          );
        }
      }
      return state;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      await analytics.purchaseEnded(
        source: source,
        packageId: package.identifier,
        productId: package.storeProduct.identifier,
        outcome: errorCode == PurchasesErrorCode.purchaseCancelledError
            ? AnalyticsPurchaseOutcome.cancelled
            : AnalyticsPurchaseOutcome.failed,
      );
      debugPrint("Purchase failed: $e");
      return false;
    } catch (e) {
      await analytics.purchaseEnded(
        source: source,
        packageId: package.identifier,
        productId: package.storeProduct.identifier,
        outcome: AnalyticsPurchaseOutcome.failed,
      );
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
    _identifiedUserId = null;
    _identitySyncUserId = null;
    _identitySyncFuture = null;
    _ref.read(customerInfoProvider.notifier).state = null;
    state = false;
  }

  bool _hasActiveEntitlement(CustomerInfo customerInfo) {
    final entitlementId = RevenueCatConfig.premiumEntitlementId;
    if (entitlementId.isEmpty) return false;
    return customerInfo.entitlements.active.containsKey(entitlementId);
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
