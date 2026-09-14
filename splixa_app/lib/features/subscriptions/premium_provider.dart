import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/analytics_service.dart';
import 'revenuecat_config.dart';

const freeGroupLimit = 2;
const freePersonalExpenseMonthlyLimit = 50;

final premiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier(ref);
});

final customerInfoProvider = StateProvider<CustomerInfo?>((ref) => null);

class ProUsage {
  const ProUsage({
    required this.isPro,
    required this.groupCount,
    required this.groupLimit,
    required this.personalExpenseCount,
    required this.personalExpenseLimit,
    required this.periodStart,
    required this.periodEnd,
  });

  final bool isPro;
  final int groupCount;
  final int groupLimit;
  final int personalExpenseCount;
  final int personalExpenseLimit;
  final DateTime periodStart;
  final DateTime periodEnd;

  int get remainingGroups =>
      (groupLimit - groupCount).clamp(0, groupLimit).toInt();
  int get remainingPersonalExpenses =>
      (personalExpenseLimit - personalExpenseCount)
          .clamp(0, personalExpenseLimit)
          .toInt();

  factory ProUsage.fromJson(Map<String, dynamic> json) => ProUsage(
    isPro: json['is_pro'] == true,
    groupCount: (json['group_count'] as num?)?.toInt() ?? 0,
    groupLimit: (json['group_limit'] as num?)?.toInt() ?? freeGroupLimit,
    personalExpenseCount:
        (json['personal_expense_count'] as num?)?.toInt() ?? 0,
    personalExpenseLimit:
        (json['personal_expense_limit'] as num?)?.toInt() ??
        freePersonalExpenseMonthlyLimit,
    periodStart: DateTime.parse(json['period_start'] as String).toUtc(),
    periodEnd: DateTime.parse(json['period_end'] as String).toUtc(),
  );
}

final proUsageProvider = FutureProvider<ProUsage?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  final response = await Supabase.instance.client.rpc('pro_usage_v1');
  if (response is! Map) throw StateError('Unexpected pro_usage_v1 response');
  return ProUsage.fromJson(Map<String, dynamic>.from(response));
});

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

      await _restoreLastVerifiedAccess();

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
    await _syncBackendEntitlement();
  }

  void _updatePremiumStatus(CustomerInfo customerInfo) {
    _ref.read(customerInfoProvider.notifier).state = customerInfo;
    if (RevenueCatConfig.premiumEntitlementId.isEmpty) return;

    final hasRevenueCatEntitlement = _hasActiveEntitlement(customerInfo);
    final isPro = _reviewAccess || hasRevenueCatEntitlement;

    if (mounted && state != isPro) {
      state = isPro;
    }
    unawaited(_cacheVerifiedAccess(customerInfo, isPro));
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
        await _syncBackendEntitlement();
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
      await _syncBackendEntitlement();
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

  Future<void> _syncBackendEntitlement() async {
    try {
      await Supabase.instance.client.functions
          .invoke('sync-pro-entitlement')
          .timeout(const Duration(seconds: 6));
      _ref.invalidate(proUsageProvider);
    } catch (error) {
      // RevenueCat's cached CustomerInfo continues to control local access.
      // The server projection will recover on the signed webhook or next sync.
      debugPrint('Backend entitlement sync deferred: $error');
    }
  }

  String? get _accessCacheKey {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return userId == null ? null : 'verified_pro_access_v1_$userId';
  }

  Future<void> _restoreLastVerifiedAccess() async {
    final key = _accessCacheKey;
    if (key == null) return;
    final preferences = await SharedPreferences.getInstance();
    final cachedUntil = DateTime.tryParse(preferences.getString(key) ?? '');
    if (cachedUntil != null && cachedUntil.isAfter(DateTime.now().toUtc())) {
      if (mounted) state = true;
    }
  }

  Future<void> _cacheVerifiedAccess(
    CustomerInfo customerInfo,
    bool isPro,
  ) async {
    final key = _accessCacheKey;
    if (key == null) return;
    final preferences = await SharedPreferences.getInstance();
    if (!isPro || _reviewAccess) {
      await preferences.remove(key);
      return;
    }
    final entitlement =
        customerInfo.entitlements.active[RevenueCatConfig.premiumEntitlementId];
    if (entitlement == null) {
      await preferences.remove(key);
      return;
    }
    final now = DateTime.now().toUtc();
    final storeExpiration = DateTime.tryParse(entitlement.expirationDate ?? '');
    final boundedOfflineExpiry = now.add(const Duration(days: 7));
    final cachedUntil =
        storeExpiration == null || storeExpiration.isAfter(boundedOfflineExpiry)
        ? boundedOfflineExpiry
        : storeExpiration;
    await preferences.setString(key, cachedUntil.toIso8601String());
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
  if (kIsWeb || !await Purchases.isConfigured) return null;
  return Purchases.getOfferings();
});

final trialEligibilityProvider =
    FutureProvider.family<IntroEligibilityStatus, String>((
      ref,
      productId,
    ) async {
      if (kIsWeb || !await Purchases.isConfigured) {
        return IntroEligibilityStatus.introEligibilityStatusUnknown;
      }
      final result = await Purchases.checkTrialOrIntroductoryPriceEligibility([
        productId,
      ]);
      return result[productId]?.status ??
          IntroEligibilityStatus.introEligibilityStatusUnknown;
    });
