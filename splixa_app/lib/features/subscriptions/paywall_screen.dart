import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics_service.dart';
import '../../core/app_strings.dart';
import '../../core/experiment_service.dart';
import '../../core/friendly_error.dart';
import '../../core/locale_provider.dart';
import '../../core/splixa_design.dart';
import '../../core/splixa_loading.dart';
import 'premium_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.source = PaywallSource.unknown});

  final PaywallSource source;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String? _selectedPackageId;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  late final AnalyticsService _analytics;
  final Stopwatch _viewDuration = Stopwatch();
  bool _dismissTracked = false;
  bool _purchaseCompleted = false;

  @override
  void initState() {
    super.initState();
    _analytics = ref.read(analyticsServiceProvider);
    _viewDuration.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _analytics.paywallView(source: widget.source);
    });
  }

  @override
  void dispose() {
    _trackDismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PaywallCopy(ref.watch(appLanguageProvider));
    final offerings = ref.watch(offeringsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final plans = _buildOfferings(context, copy, offerings, colorScheme);
    final benefits = _buildBenefits(context, copy);
    final plansFirst =
        ExperimentService.instance.paywallVariant ==
        PaywallExperimentVariant.plansFirst;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: copy.close,
          icon: const Icon(Icons.close_rounded),
          onPressed: _isPurchasing ? null : _close,
        ),
        title: Text(copy.appBarTitle),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            _PaywallHero(copy: copy),
            const SizedBox(height: 22),
            if (plansFirst) ...[
              plans,
              const SizedBox(height: 24),
              ...benefits,
            ] else ...[
              ...benefits,
              const SizedBox(height: 24),
              plans,
            ],
            const SizedBox(height: 14),
            TextButton(
              onPressed: _isPurchasing ? null : _close,
              child: Text(copy.continueFree),
            ),
            TextButton(
              onPressed: _isPurchasing || _isRestoring
                  ? null
                  : () => _restore(copy),
              child: _isRestoring
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(copy.restore),
            ),
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      _openLegal(Uri.parse('https://splixa.net/terms'), copy),
                  child: Text(copy.terms),
                ),
                Text('•', style: TextStyle(color: colorScheme.outline)),
                TextButton(
                  onPressed: () =>
                      _openLegal(Uri.parse('https://splixa.net/privacy'), copy),
                  child: Text(copy.privacy),
                ),
              ],
            ),
            Text(
              copy.storeDisclosure,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBenefits(BuildContext context, _PaywallCopy copy) {
    return [
      Text(
        copy.benefitsTitle,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 12),
      ...copy.benefits.map(
        (benefit) => _BenefitRow(
          icon: benefit.icon,
          title: benefit.title,
          description: benefit.description,
        ),
      ),
    ];
  }

  Widget _buildOfferings(
    BuildContext context,
    _PaywallCopy copy,
    AsyncValue<Offerings?> offerings,
    ColorScheme colorScheme,
  ) {
    return offerings.when(
      loading: () => const SplixaSkeletonView(
        type: SplixaSkeletonType.paywall,
        padding: EdgeInsets.symmetric(vertical: 8),
      ),
      error: (error, _) => _OfferingsError(
        message: friendlyErrorMessage(error),
        retryLabel: copy.retry,
        onRetry: () => ref.invalidate(offeringsProvider),
      ),
      data: (offerings) {
        final packages = _orderedPackages(
          offerings?.current?.availablePackages ?? const [],
        );
        if (packages.isEmpty) {
          return _OfferingsError(
            message: copy.noPackages,
            retryLabel: copy.retry,
            onRetry: () => ref.invalidate(offeringsProvider),
          );
        }

        final selected = _selectedPackage(packages);
        final selectedEligibility = ref.watch(
          trialEligibilityProvider(selected.storeProduct.identifier),
        );
        final selectedHasSevenDayTrial = _hasEligibleSevenDayTrial(
          selected,
          selectedEligibility.value,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              copy.choosePlan,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...packages.map(
              (package) => _PlanCard(
                package: package,
                selected: package.identifier == selected.identifier,
                recommended: _isBestValue(package, packages),
                copy: copy,
                onTap: _isPurchasing ? null : () => _selectPackage(package),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              copy.renewalDisclosure(
                selected,
                hasEligibleSevenDayTrial: selectedHasSevenDayTrial,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SplixaPrimaryButton(
              label: copy.continueWith(selected),
              icon: Icons.lock_open_rounded,
              loading: _isPurchasing,
              onPressed: () => _purchase(selected, copy),
            ),
          ],
        );
      },
    );
  }

  List<Package> _orderedPackages(List<Package> packages) {
    final result = List<Package>.from(packages);
    int priority(Package package) => switch (package.packageType) {
      PackageType.annual => 0,
      PackageType.monthly => 1,
      PackageType.lifetime => 2,
      _ => 2,
    };
    result.sort((a, b) => priority(a).compareTo(priority(b)));
    return result;
  }

  bool _isBestValue(Package package, List<Package> packages) {
    if (package.packageType != PackageType.annual) return false;

    final monthlyPackages = packages.where(
      (candidate) => candidate.packageType == PackageType.monthly,
    );
    if (monthlyPackages.isEmpty) return false;

    return package.storeProduct.price <
        monthlyPackages.first.storeProduct.price * 12;
  }

  Package _selectedPackage(List<Package> packages) {
    final selectedId = _selectedPackageId;
    if (selectedId != null) {
      for (final package in packages) {
        if (package.identifier == selectedId) return package;
      }
    }
    return packages.first;
  }

  Future<void> _purchase(Package package, _PaywallCopy copy) async {
    if (_isPurchasing) return;
    setState(() => _isPurchasing = true);

    final success = await ref
        .read(premiumProvider.notifier)
        .purchasePackage(package, source: widget.source);

    if (!mounted) return;
    setState(() => _isPurchasing = false);
    if (success) {
      _purchaseCompleted = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.welcome)));
      _close();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.purchaseFailed)));
    }
  }

  Future<void> _restore(_PaywallCopy copy) async {
    setState(() => _isRestoring = true);
    final success = await ref.read(premiumProvider.notifier).restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? copy.restoreSuccess : copy.restoreNone)),
    );
    if (success) _close();
  }

  Future<void> _openLegal(Uri uri, _PaywallCopy copy) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.linkFailed)));
    }
  }

  void _close() {
    _trackDismiss();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  void _selectPackage(Package package) {
    setState(() => _selectedPackageId = package.identifier);
    _analytics.paywallPackageSelected(
      source: widget.source,
      packageId: package.identifier,
      productId: package.storeProduct.identifier,
    );
  }

  void _trackDismiss() {
    if (_dismissTracked) return;
    _dismissTracked = true;
    _viewDuration.stop();
    _analytics.paywallDismissed(
      source: widget.source,
      purchaseCompleted: _purchaseCompleted,
      durationMilliseconds: _viewDuration.elapsedMilliseconds,
    );
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero({required this.copy});

  final _PaywallCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [SplixaColors.cyan, Color(0xFF155E75)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 88,
            child: Lottie.asset(
              'assets/lottie/pro_value.json',
              animate: !MediaQuery.disableAnimationsOf(context),
              repeat: true,
              errorBuilder: (_, _, _) => const Icon(
                Icons.auto_awesome_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            copy.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .90),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.package,
    required this.selected,
    required this.recommended,
    required this.copy,
    required this.onTap,
  });

  final Package package;
  final bool selected;
  final bool recommended;
  final _PaywallCopy copy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = package.storeProduct;
    final appleEligibility = ref.watch(
      trialEligibilityProvider(product.identifier),
    );
    final hasEligibleTrial = _hasEligibleSevenDayTrial(
      package,
      appleEligibility.value,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? colorScheme.primaryContainer.withValues(alpha: .55)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected ? colorScheme.primary : colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              copy.planName(package),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (recommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE08A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                copy.bestValue,
                                style: const TextStyle(
                                  color: Color(0xFF6D4800),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          if (hasEligibleTrial) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                copy.freeTrial,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (package.packageType == PackageType.annual &&
                          product.pricePerMonthString != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          copy.monthlyEquivalent(product.pricePerMonthString!),
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.priceString,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      copy.period(package),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferingsError extends StatelessWidget {
  const _OfferingsError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 32),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _BenefitCopy {
  const _BenefitCopy(this.icon, this.title, this.description);

  final IconData icon;
  final String title;
  final String description;
}

/// Paywall copy resolved from the shared localization catalog.
///
/// Prices are never part of this class: every amount shown on the paywall
/// comes from RevenueCat's `StoreProduct.priceString`, which is already
/// formatted in the store account's currency and locale.
class _PaywallCopy {
  const _PaywallCopy(this.language);

  final AppLanguage language;

  String _s(String key) => AppStrings.of(key, language);
  String _f(String key, Map<String, String> values) =>
      AppStrings.format(key, language, values);

  String get appBarTitle => _s('paywall_appbar_title');
  String get close => _s('paywall_close');
  String get title => _s('paywall_hero_title');
  String get subtitle => _s('paywall_hero_subtitle');
  String get benefitsTitle => _s('paywall_benefits_title');
  String get choosePlan => _s('paywall_choose_plan');
  String get bestValue => _s('paywall_best_value');
  String get freeTrial => _s('paywall_free_trial');
  String get continueFree => _s('paywall_continue_free');
  String get restore => _s('paywall_restore');
  String get restoreSuccess => _s('paywall_restore_restored');
  String get restoreNone => _s('paywall_restore_none');
  String get welcome => _s('paywall_welcome_message');
  String get purchaseFailed => _s('paywall_purchase_failed_message');
  String get noPackages => _s('paywall_no_packages_available');
  String get retry => _s('paywall_retry');
  String get terms => _s('paywall_terms_link');
  String get privacy => _s('paywall_privacy_link');
  String get storeDisclosure => _s('paywall_store_disclosure');
  String get linkFailed => _s('paywall_link_failed');

  List<_BenefitCopy> get benefits => [
    _BenefitCopy(
      Icons.groups_rounded,
      _s('paywall_benefit_1_title'),
      _s('paywall_benefit_1_body'),
    ),
    _BenefitCopy(
      Icons.insights_rounded,
      _s('paywall_benefit_2_title'),
      _s('paywall_benefit_2_body'),
    ),
    _BenefitCopy(
      Icons.file_download_rounded,
      _s('paywall_benefit_3_title'),
      _s('paywall_benefit_3_body'),
    ),
    _BenefitCopy(
      Icons.auto_awesome_rounded,
      _s('paywall_benefit_4_title'),
      _s('paywall_benefit_4_body'),
    ),
  ];

  String planName(Package package) => switch (package.packageType) {
    PackageType.annual => _s('paywall_plan_annual'),
    PackageType.monthly => _s('paywall_plan_monthly'),
    PackageType.lifetime => _s('paywall_plan_lifetime'),
    _ => package.storeProduct.title,
  };

  String period(Package package) => switch (package.packageType) {
    PackageType.annual => _s('paywall_period_annual'),
    PackageType.monthly => _s('paywall_period_monthly'),
    PackageType.lifetime => _s('paywall_period_once'),
    _ => '',
  };

  String monthlyEquivalent(String price) =>
      _f('paywall_monthly_equivalent', {'price': price});

  String continueWith(Package package) =>
      _f('paywall_continue_with_plan', {'plan': planName(package)});

  String renewalDisclosure(
    Package package, {
    required bool hasEligibleSevenDayTrial,
  }) {
    final price = package.storeProduct.priceString;
    final key = switch (package.packageType) {
      PackageType.annual => 'paywall_renewal_annual',
      PackageType.lifetime => 'paywall_lifetime_disclosure',
      _ => 'paywall_renewal_monthly',
    };
    final disclosure = _f(key, {'price': price});
    return hasEligibleSevenDayTrial
        ? '${_s('paywall_free_trial')}. $disclosure'
        : disclosure;
  }
}

bool _hasEligibleSevenDayTrial(
  Package package,
  IntroEligibilityStatus? appleEligibility,
) {
  if (package.packageType != PackageType.monthly) return false;
  final product = package.storeProduct;
  final androidPeriod = product.defaultOption?.freePhase?.billingPeriod;
  final hasAndroidWeek = androidPeriod?.iso8601 == 'P1W';
  final appleIntro = product.introductoryPrice;
  final hasEligibleAppleWeek =
      appleIntro?.price == 0 &&
      appleIntro?.period == 'P1W' &&
      appleIntro?.cycles == 1 &&
      appleEligibility == IntroEligibilityStatus.introEligibilityStatusEligible;
  return hasAndroidWeek || hasEligibleAppleWeek;
}
