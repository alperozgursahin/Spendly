import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics_service.dart';
import 'premium_provider.dart';

enum ProFeature {
  unlimitedGroups('unlimited_groups', PaywallSource.unlimitedGroups),
  personalExpenses('personal_expenses', PaywallSource.personalExpenseLimit),
  biometricLock('biometric_lock', PaywallSource.biometricLock),
  homeWidget('home_widget', PaywallSource.homeWidget),
  receiptAttachment('receipt_attachment', PaywallSource.receiptAttachment),
  customCategories('custom_categories', PaywallSource.customCategories),
  recurringExpenses('recurring_expenses', PaywallSource.recurringExpenses),
  debtReminders('debt_reminders', PaywallSource.debtReminders),
  receiptScanner('receipt_scanner', PaywallSource.receiptScan),
  advancedReports('advanced_reports', PaywallSource.advancedReports),
  tripSummary('trip_summary', PaywallSource.tripSummary),
  advancedAnalytics('advanced_analytics', PaywallSource.advancedAnalytics),
  customExchangeRate('custom_exchange_rate', PaywallSource.customExchangeRate);

  const ProFeature(this.analyticsValue, this.paywallSource);
  final String analyticsValue;
  final PaywallSource paywallSource;
}

/// Returns true only when the feature may continue. Locked taps are measured
/// and routed to a source-specific paywall; database policies remain the final
/// authorization layer for every paid write.
Future<bool> requirePro(
  BuildContext context,
  WidgetRef ref,
  ProFeature feature,
) async {
  await ref
      .read(analyticsServiceProvider)
      .proFeatureSelected(feature: feature.analyticsValue);
  if (ref.read(premiumProvider)) return true;
  if (!context.mounted) return false;
  await context.push('/paywall?source=${feature.paywallSource.analyticsValue}');
  return ref.read(premiumProvider);
}
