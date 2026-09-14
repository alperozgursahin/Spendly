import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics_service.dart';
import '../../core/app_strings.dart';
import '../../core/experiment_service.dart';
import '../../core/friendly_error.dart';
import '../../core/locale_provider.dart';
import '../../core/splixa_design.dart';
import '../../core/splixa_loading.dart';
import '../onboarding/onboarding_art.dart';
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
        final selectedTrialPeriod = _freeTrialPeriod(
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
                savingsPercent: _annualSavingsPercent(package, packages),
                copy: copy,
                onTap: _isPurchasing ? null : () => _selectPackage(package),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              copy.renewalDisclosure(
                selected,
                trialPeriod: selectedTrialPeriod,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            SplixaPrimaryButton(
              // Naming the trial in the button is the single highest-leverage
              // wording change on a paywall: the commitment the user is being
              // asked for should match what actually happens when they tap.
              label: selectedTrialPeriod == null
                  ? copy.continueWith(selected)
                  : copy.startTrialCta(selectedTrialPeriod),
              icon: selectedTrialPeriod == null
                  ? Icons.lock_open_rounded
                  : Icons.play_arrow_rounded,
              loading: _isPurchasing,
              onPressed: () => _purchase(selected, copy),
            ),
            const SizedBox(height: 14),
            _TrustRow(copy: copy, hasTrial: selectedTrialPeriod != null),
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

  /// How much the annual plan saves against paying monthly for a year, as a
  /// whole percent, or null when there is nothing to claim.
  ///
  /// A concrete "SAVE 38%" outperforms an abstract "best value" badge, and
  /// computing it from the two live store prices means it can never drift out
  /// of date the way a hard-coded number would when prices change.
  int? _annualSavingsPercent(Package package, List<Package> packages) {
    if (package.packageType != PackageType.annual) return null;

    final monthlyPackages = packages.where(
      (candidate) => candidate.packageType == PackageType.monthly,
    );
    if (monthlyPackages.isEmpty) return null;

    final yearAtMonthlyRate = monthlyPackages.first.storeProduct.price * 12;
    if (yearAtMonthlyRate <= 0) return null;
    final saved = (1 - package.storeProduct.price / yearAtMonthlyRate) * 100;
    // Under five percent is not worth a badge; it reads as a rounding error.
    return saved < 5 ? null : saved.floor();
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
          // Was the same placeholder Lottie as the old onboarding -- a circle
          // orbiting a tick. Reuses the Pro scene instead, so the paywall and
          // the last onboarding slide show the same object and the upgrade is
          // recognisable as the thing that was just described.
          SizedBox(
            height: 108,
            child: OnboardingArt(
              scene: OnboardingScene.pro,
              accent: Colors.white,
              reduceMotion: MediaQuery.disableAnimationsOf(context),
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
    required this.savingsPercent,
    required this.copy,
    required this.onTap,
  });

  final Package package;
  final bool selected;

  /// Percent saved versus paying monthly, or null when this plan has no claim
  /// to make.
  final int? savingsPercent;
  final _PaywallCopy copy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = package.storeProduct;
    final appleEligibility = ref.watch(
      trialEligibilityProvider(product.identifier),
    );
    final trialPeriod = _freeTrialPeriod(package, appleEligibility.value);
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
                          if (savingsPercent != null) ...[
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
                                copy.savePercent(savingsPercent!),
                                style: const TextStyle(
                                  color: Color(0xFF6D4800),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                          if (trialPeriod != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                copy.freeTrial(trialPeriod),
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

/// Three short reassurances under the CTA.
///
/// Deliberately factual -- what the subscription actually does -- rather than
/// star ratings or install counts. Invented social proof is the fastest way to
/// make a paywall feel less trustworthy, not more, and the real numbers are not
/// ours to quote yet.
class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.copy, required this.hasTrial});

  final _PaywallCopy copy;
  final bool hasTrial;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = <({IconData icon, String label})>[
      (icon: Icons.cancel_schedule_send_rounded, label: copy.trustCancel),
      if (hasTrial)
        (icon: Icons.money_off_csred_rounded, label: copy.trustNoCharge),
      (icon: Icons.verified_user_rounded, label: copy.trustStore),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: items
          .map(
            (item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
          .toList(),
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

  String savePercent(int percent) =>
      _f('paywall_save_percent', {'percent': '$percent'});

  /// CTA for a plan that opens with a free trial. Falls back to untimed wording
  /// when the store reports a period that is not a whole number of days.
  String startTrialCta(String iso8601) {
    final days = _trialDays(iso8601);
    return days == null
        ? _s('paywall_start_trial_cta_generic')
        : _f('paywall_start_trial_cta', {'days': '$days'});
  }

  String get trustCancel => _s('paywall_trust_cancel');
  String get trustNoCharge => _s('paywall_trust_no_charge');
  String get trustStore => _s('paywall_trust_store');

  /// Badge text for a trial of [iso8601]. Falls back to untimed wording when
  /// the period is not expressible in whole days.
  String freeTrial(String? iso8601) {
    final days = _trialDays(iso8601);
    return days == null
        ? _s('paywall_free_trial_generic')
        : _f('paywall_free_trial_days', {'days': '$days'});
  }

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

  String renewalDisclosure(Package package, {String? trialPeriod}) {
    final price = package.storeProduct.priceString;
    final key = switch (package.packageType) {
      PackageType.annual => 'paywall_renewal_annual',
      PackageType.lifetime => 'paywall_lifetime_disclosure',
      _ => 'paywall_renewal_monthly',
    };
    final disclosure = _f(key, {'price': price});
    return trialPeriod == null
        ? disclosure
        : '${freeTrial(trialPeriod)}. $disclosure';
  }
}

/// The free trial the store is actually offering on this package, as an
/// ISO-8601 duration, or null when there is none.
///
/// The previous version missed a trial that was really there, in three separate
/// ways. It bailed out unless the package was `PackageType.monthly`, so a trial
/// configured on the annual base plan could never appear. It only looked at
/// `defaultOption`, but Play exposes the trial as its own entry in
/// `subscriptionOptions` and only promotes it to the default in some cases. And
/// it demanded the period be exactly `P1W`, so the same seven days entered as
/// `P7D` did not count. Any free phase on any option now counts, and the badge
/// renders whatever length the store reports rather than a hard-coded week.
String? _freeTrialPeriod(
  Package package,
  IntroEligibilityStatus? appleEligibility,
) {
  final product = package.storeProduct;

  // Android. `freePhase` is already "the phase that costs nothing", so finding
  // one on any option is enough.
  for (final option in <SubscriptionOption?>[
    product.defaultOption,
    ...?product.subscriptionOptions,
  ]) {
    final period = option?.freePhase?.billingPeriod?.iso8601;
    if (period != null && period.isNotEmpty) return period;
  }

  // iOS. A zero-price introductory offer counts only when StoreKit says this
  // Apple ID has not already used it; showing it otherwise is a false promise.
  final intro = product.introductoryPrice;
  if (intro != null &&
      intro.price == 0 &&
      intro.period.isNotEmpty &&
      appleEligibility ==
          IntroEligibilityStatus.introEligibilityStatusEligible) {
    return intro.period;
  }
  return null;
}

/// Whole days in an ISO-8601 subscription period, or null if it is not a
/// day-or-week duration. Months and years deliberately return null: "30-day
/// free trial" for a `P1M` offer would be wrong in any month that is not
/// thirty days long, so those fall back to untimed copy.
int? _trialDays(String? iso8601) {
  if (iso8601 == null) return null;
  final match = RegExp(r'^P(\d+)([DW])$').firstMatch(iso8601);
  if (match == null) return null;
  final value = int.tryParse(match.group(1)!);
  if (value == null || value <= 0) return null;
  return match.group(2) == 'W' ? value * 7 : value;
}
