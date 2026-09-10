import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics_service.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_design.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(analyticsServiceProvider).paywallView(source: widget.source);
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = _PaywallCopy.forLocale(Localizations.localeOf(context));
    final offerings = ref.watch(offeringsProvider);
    final colorScheme = Theme.of(context).colorScheme;

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
            const SizedBox(height: 24),
            offerings.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 44),
                child: Center(child: CircularProgressIndicator()),
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy.choosePlan,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...packages.map(
                      (package) => _PlanCard(
                        package: package,
                        selected: package.identifier == selected.identifier,
                        recommended: _isBestValue(package, packages),
                        copy: copy,
                        onTap: _isPurchasing
                            ? null
                            : () => setState(
                                () => _selectedPackageId = package.identifier,
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      copy.renewalDisclosure(selected),
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
            ),
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

  List<Package> _orderedPackages(List<Package> packages) {
    final result = List<Package>.from(packages);
    int priority(Package package) => switch (package.packageType) {
      PackageType.annual => 0,
      PackageType.monthly => 1,
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
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
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
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 38,
              color: Colors.white,
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

class _PlanCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final product = package.storeProduct;
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

class _PaywallCopy {
  const _PaywallCopy({
    required this.appBarTitle,
    required this.close,
    required this.title,
    required this.subtitle,
    required this.benefitsTitle,
    required this.benefits,
    required this.choosePlan,
    required this.bestValue,
    required this.continueFree,
    required this.restore,
    required this.restoreSuccess,
    required this.restoreNone,
    required this.welcome,
    required this.purchaseFailed,
    required this.noPackages,
    required this.retry,
    required this.terms,
    required this.privacy,
    required this.storeDisclosure,
    required this.linkFailed,
    required this.isTurkish,
  });

  final String appBarTitle;
  final String close;
  final String title;
  final String subtitle;
  final String benefitsTitle;
  final List<_BenefitCopy> benefits;
  final String choosePlan;
  final String bestValue;
  final String continueFree;
  final String restore;
  final String restoreSuccess;
  final String restoreNone;
  final String welcome;
  final String purchaseFailed;
  final String noPackages;
  final String retry;
  final String terms;
  final String privacy;
  final String storeDisclosure;
  final String linkFailed;
  final bool isTurkish;

  static _PaywallCopy forLocale(Locale locale) {
    return locale.languageCode == 'tr' ? _turkish : _english;
  }

  String planName(Package package) => switch (package.packageType) {
    PackageType.annual => isTurkish ? 'Yıllık Pro' : 'Yearly Pro',
    PackageType.monthly => isTurkish ? 'Aylık Pro' : 'Monthly Pro',
    _ => package.storeProduct.title,
  };

  String period(Package package) => switch (package.packageType) {
    PackageType.annual => isTurkish ? '/ yıl' : '/ year',
    PackageType.monthly => isTurkish ? '/ ay' : '/ month',
    _ => '',
  };

  String monthlyEquivalent(String price) =>
      isTurkish ? 'Aylık karşılığı $price' : '$price monthly equivalent';

  String continueWith(Package package) => isTurkish
      ? '${planName(package)} ile devam et'
      : 'Continue with ${planName(package)}';

  String renewalDisclosure(Package package) {
    final price = package.storeProduct.priceString;
    final cadence = package.packageType == PackageType.annual
        ? (isTurkish ? 'yıllık' : 'yearly')
        : (isTurkish ? 'aylık' : 'monthly');
    return isTurkish
        ? 'Şimdi $price tahsil edilir. Abonelik iptal edilene kadar $cadence '
              'olarak otomatik yenilenir.'
        : '$price is charged now. The subscription renews $cadence until '
              'cancelled.';
  }

  static const _english = _PaywallCopy(
    appBarTitle: 'Splixa Pro',
    close: 'Close',
    title: 'Turn money admin into a two-minute task',
    subtitle:
        'Keep Splixa’s core free. Go Pro when automation, control, and deeper '
        'answers are worth more than the time they save.',
    benefitsTitle: 'What Pro unlocks',
    benefits: [
      _BenefitCopy(
        Icons.groups_rounded,
        'Unlimited groups',
        'Keep every trip, household, and project active without a group cap.',
      ),
      _BenefitCopy(
        Icons.insights_rounded,
        'See the patterns behind spending',
        'Explore category distribution and activity patterns at a glance.',
      ),
      _BenefitCopy(
        Icons.file_download_rounded,
        'Export polished monthly reports',
        'Turn your personal records into a shareable PDF in one tap.',
      ),
      _BenefitCopy(
        Icons.auto_awesome_rounded,
        'Roadmap preview: less typing, more control',
        'Receipt scanning and custom exchange rates are coming next.',
      ),
    ],
    choosePlan: 'Choose your plan',
    bestValue: 'BEST VALUE',
    continueFree: 'Not now — continue with free',
    restore: 'Restore purchases',
    restoreSuccess: 'Your Pro access has been restored.',
    restoreNone: 'No active Pro purchase was found for this store account.',
    welcome: 'Welcome to Splixa Pro.',
    purchaseFailed: 'The purchase was cancelled or could not be completed.',
    noPackages: 'Plans are temporarily unavailable. Please try again.',
    retry: 'Try again',
    terms: 'Terms of Use',
    privacy: 'Privacy Policy',
    storeDisclosure:
        'Payment is charged to your store account. Manage or cancel from your '
        'App Store or Google Play subscription settings.',
    linkFailed: 'The page could not be opened.',
    isTurkish: false,
  );

  static const _turkish = _PaywallCopy(
    appBarTitle: 'Splixa Pro',
    close: 'Kapat',
    title: 'Para işlerini iki dakikalık bir göreve dönüştür',
    subtitle:
        'Splixa’nın temeli ücretsiz kalsın. Otomasyon, kontrol ve derin '
        'yanıtlar kazandırdığı zamandan değerli olduğunda Pro’ya geç.',
    benefitsTitle: 'Pro ile açılanlar',
    benefits: [
      _BenefitCopy(
        Icons.groups_rounded,
        'Limitsiz grup',
        'Her geziyi, evi ve projeyi grup sınırı olmadan aktif tut.',
      ),
      _BenefitCopy(
        Icons.insights_rounded,
        'Harcamaların ardındaki deseni gör',
        'Kategori dağılımını ve harcama hareketlerini tek bakışta incele.',
      ),
      _BenefitCopy(
        Icons.file_download_rounded,
        'Düzenli aylık raporlar çıkar',
        'Kişisel kayıtlarını tek dokunuşla paylaşılabilir PDF’e dönüştür.',
      ),
      _BenefitCopy(
        Icons.auto_awesome_rounded,
        'Yol haritası: daha az yazma, daha çok kontrol',
        'Fiş tarama ve özel döviz kurları sıradaki Pro araçlarıdır.',
      ),
    ],
    choosePlan: 'Planını seç',
    bestValue: 'EN AVANTAJLI',
    continueFree: 'Şimdi değil — ücretsiz devam et',
    restore: 'Satın alımları geri yükle',
    restoreSuccess: 'Pro erişimin geri yüklendi.',
    restoreNone: 'Bu mağaza hesabında etkin Pro satın alımı bulunamadı.',
    welcome: 'Splixa Pro’ya hoş geldin.',
    purchaseFailed: 'Satın alma iptal edildi veya tamamlanamadı.',
    noPackages: 'Planlara geçici olarak ulaşılamıyor. Tekrar dene.',
    retry: 'Tekrar dene',
    terms: 'Kullanım Koşulları',
    privacy: 'Gizlilik Politikası',
    storeDisclosure:
        'Ödeme mağaza hesabından alınır. Aboneliğini App Store veya Google '
        'Play abonelik ayarlarından yönetebilir ya da iptal edebilirsin.',
    linkFailed: 'Sayfa açılamadı.',
    isTurkish: true,
  );
}
