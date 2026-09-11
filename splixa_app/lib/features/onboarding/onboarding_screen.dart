import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics_service.dart';
import '../../core/splixa_design.dart';

class OnboardingController extends ChangeNotifier {
  factory OnboardingController({required bool completed}) {
    return OnboardingController._(completed);
  }

  OnboardingController._(this._completed);

  static const _storageKey = 'splixa_onboarding_completed_v1';

  bool _completed;
  bool get completed => _completed;
  bool _completedThisRun = false;
  bool get completedThisRun => _completedThisRun;

  static Future<OnboardingController> load() async {
    final preferences = await SharedPreferences.getInstance();
    return OnboardingController(
      completed: preferences.getBool(_storageKey) ?? false,
    );
  }

  Future<void> complete() async {
    _completedThisRun = true;
    if (_completed) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_storageKey, true);
    _completed = true;
    notifyListeners();
  }

  Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    _completedThisRun = false;
    if (!_completed) return;
    _completed = false;
    notifyListeners();
  }
}

final onboardingControllerProvider =
    ChangeNotifierProvider<OnboardingController>((ref) {
      return OnboardingController(completed: false);
    });

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final Set<int> _trackedSteps = <int>{};
  int _currentPage = 0;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final analytics = ref.read(analyticsServiceProvider);
      analytics.onboardingStart();
      _trackStep(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = _OnboardingCopy.forLocale(Localizations.localeOf(context));
    final pages = copy.pages;
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
              child: Row(
                children: [
                  const SplixaLogo(compact: true),
                  const Spacer(),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _isCompleting
                          ? null
                          : () => _finish(copy, 'skip'),
                      child: Text(copy.skip),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: pages.length,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  _trackStep(page);
                },
                itemBuilder: (context, index) => _OnboardingPage(
                  key: ValueKey(pages[index].analyticsName),
                  page: pages[index],
                  step: index + 1,
                  totalSteps: pages.length,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        width: index == _currentPage ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant
                                    .withValues(alpha: .65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SplixaPrimaryButton(
                    label: isLastPage ? copy.startFree : copy.continueLabel,
                    icon: isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    loading: _isCompleting,
                    onPressed: isLastPage
                        ? () => _finish(copy, 'completed')
                        : _nextPage,
                  ),
                  if (isLastPage) ...[
                    const SizedBox(height: 10),
                    Text(
                      copy.noCard,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _trackStep(int index) {
    if (!_trackedSteps.add(index)) return;
    final copy = _OnboardingCopy.forLocale(Localizations.localeOf(context));
    final page = copy.pages[index];
    ref
        .read(analyticsServiceProvider)
        .onboardingStepViewed(step: index + 1, stepName: page.analyticsName);
  }

  Future<void> _finish(_OnboardingCopy copy, String completionMethod) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      await ref.read(onboardingControllerProvider).complete();
      await ref
          .read(analyticsServiceProvider)
          .onboardingComplete(completionMethod: completionMethod);
      if (mounted) context.go('/login');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCompleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(copy.persistenceError)));
    }
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    super.key,
    required this.page,
    required this.step,
    required this.totalSteps,
  });

  final _OnboardingPageData page;
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Column(
        children: [
          Semantics(
            label: '$step / $totalSteps',
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              height: 250,
              decoration: BoxDecoration(
                color: isDark
                    ? SplixaColors.slate800
                    : page.accent.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: page.accent.withValues(alpha: isDark ? .45 : .22),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 28,
                    right: 30,
                    child: _OrbitIcon(
                      icon: page.supportingIcon,
                      color: page.accent,
                      size: 58,
                    ),
                  ),
                  Positioned(
                    bottom: 28,
                    left: 30,
                    child: _OrbitIcon(
                      icon: page.secondaryIcon,
                      color: page.accent,
                      size: 52,
                    ),
                  ),
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: page.accent.withValues(alpha: .18),
                          blurRadius: 34,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(page.icon, size: 64, color: page.accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            page.eyebrow,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: page.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.9,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (page.proofPoints.isNotEmpty) ...[
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: page.proofPoints
                  .map(
                    (point) => Chip(
                      avatar: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: page.accent,
                      ),
                      label: Text(point),
                      side: BorderSide(
                        color: page.accent.withValues(alpha: .22),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: .30)),
      ),
      child: Icon(icon, color: color, size: size * .46),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.analyticsName,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.supportingIcon,
    required this.secondaryIcon,
    required this.accent,
    this.proofPoints = const [],
  });

  final String analyticsName;
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final IconData supportingIcon;
  final IconData secondaryIcon;
  final Color accent;
  final List<String> proofPoints;
}

class _OnboardingCopy {
  const _OnboardingCopy({
    required this.pages,
    required this.skip,
    required this.continueLabel,
    required this.startFree,
    required this.noCard,
    required this.persistenceError,
  });

  final List<_OnboardingPageData> pages;
  final String skip;
  final String continueLabel;
  final String startFree;
  final String noCard;
  final String persistenceError;

  static _OnboardingCopy forLocale(Locale locale) {
    return locale.languageCode == 'tr' ? _turkish : _english;
  }

  static const _english = _OnboardingCopy(
    skip: 'Skip',
    continueLabel: 'Continue',
    startFree: 'Start free',
    noCard: 'No card required. Upgrade only when Pro saves you time.',
    persistenceError: 'We could not save your choice. Please try again.',
    pages: [
      _OnboardingPageData(
        analyticsName: 'unified_money_home',
        eyebrow: 'PERSONAL + SHARED',
        title: 'One calm home for every expense',
        description:
            'Track your own budget and shared group costs without switching '
            'between apps or losing the full picture.',
        icon: Icons.account_balance_wallet_rounded,
        supportingIcon: Icons.person_rounded,
        secondaryIcon: Icons.groups_rounded,
        accent: SplixaColors.cyan,
        proofPoints: ['Personal budget', 'Group expenses'],
      ),
      _OnboardingPageData(
        analyticsName: 'clear_group_splits',
        eyebrow: 'NO AWKWARD MATH',
        title: 'Split the moment, not the friendship',
        description:
            'Choose equal, percentage, or exact shares. Everyone can approve, '
            'pay, and settle with a clear history.',
        icon: Icons.call_split_rounded,
        supportingIcon: Icons.receipt_long_rounded,
        secondaryIcon: Icons.done_all_rounded,
        accent: Color(0xFF7C3AED),
        proofPoints: ['Flexible splits', 'Clear approvals'],
      ),
      _OnboardingPageData(
        analyticsName: 'trusted_multi_currency',
        eyebrow: 'MONEY THAT ADDS UP',
        title: 'Every currency keeps its story',
        description:
            'Splixa preserves the original amount and locked exchange rate, '
            'so yesterday’s balance never changes behind your back.',
        icon: Icons.currency_exchange_rounded,
        supportingIcon: Icons.lock_clock_rounded,
        secondaryIcon: Icons.history_rounded,
        accent: Color(0xFF0284C7),
        proofPoints: ['Locked rates', 'Reliable history'],
      ),
      _OnboardingPageData(
        analyticsName: 'free_first_pro_value',
        eyebrow: 'FREE TO START',
        title: 'Do the essentials free. Save time with Pro.',
        description:
            'Build the habit first. When you want receipt scanning, custom '
            'rates, deeper insights, and advanced reports, see what Pro '
            'offers now and what is next on its roadmap.',
        icon: Icons.auto_awesome_rounded,
        supportingIcon: Icons.document_scanner_rounded,
        secondaryIcon: Icons.insights_rounded,
        accent: Color(0xFFD97706),
        proofPoints: ['No forced trial', 'Cancel anytime'],
      ),
    ],
  );

  static const _turkish = _OnboardingCopy(
    skip: 'Atla',
    continueLabel: 'Devam et',
    startFree: 'Ücretsiz başla',
    noCard: 'Kart gerekmez. Yalnızca Pro zaman kazandırdığında yükselt.',
    persistenceError: 'Tercihin kaydedilemedi. Lütfen tekrar dene.',
    pages: [
      _OnboardingPageData(
        analyticsName: 'unified_money_home',
        eyebrow: 'KİŞİSEL + ORTAK',
        title: 'Her harcama için sakin ve tek bir yer',
        description:
            'Kişisel bütçeni ve grup harcamalarını uygulamalar arasında '
            'kaybolmadan, bütün resmi görerek takip et.',
        icon: Icons.account_balance_wallet_rounded,
        supportingIcon: Icons.person_rounded,
        secondaryIcon: Icons.groups_rounded,
        accent: SplixaColors.cyan,
        proofPoints: ['Kişisel bütçe', 'Grup harcamaları'],
      ),
      _OnboardingPageData(
        analyticsName: 'clear_group_splits',
        eyebrow: 'GERGİNLİK YOK, HESAP NET',
        title: 'Anı paylaş, arkadaşlığı değil',
        description:
            'Eşit, yüzdelik veya kesin tutarla böl. Herkes onay, ödeme ve '
            'kapanış adımlarını açık bir geçmişte görsün.',
        icon: Icons.call_split_rounded,
        supportingIcon: Icons.receipt_long_rounded,
        secondaryIcon: Icons.done_all_rounded,
        accent: Color(0xFF7C3AED),
        proofPoints: ['Esnek bölüşüm', 'Açık onaylar'],
      ),
      _OnboardingPageData(
        analyticsName: 'trusted_multi_currency',
        eyebrow: 'GÜVENİLİR HESAPLAR',
        title: 'Her para birimi hikâyesini korur',
        description:
            'Splixa orijinal tutarı ve kilitli döviz kurunu saklar; dünün '
            'bakiyesi bugün kendiliğinden değişmez.',
        icon: Icons.currency_exchange_rounded,
        supportingIcon: Icons.lock_clock_rounded,
        secondaryIcon: Icons.history_rounded,
        accent: Color(0xFF0284C7),
        proofPoints: ['Kilitli kurlar', 'Güvenilir geçmiş'],
      ),
      _OnboardingPageData(
        analyticsName: 'free_first_pro_value',
        eyebrow: 'BAŞLAMAK ÜCRETSİZ',
        title: 'Temel işler ücretsiz. Pro ile zaman senin.',
        description:
            'Önce alışkanlığını kur. Fiş tarama, özel kur, derin içgörüler '
            've gelişmiş raporlar için Pro’da bugün sunulanları ve sıradaki '
            'yol haritasını gör.',
        icon: Icons.auto_awesome_rounded,
        supportingIcon: Icons.document_scanner_rounded,
        secondaryIcon: Icons.insights_rounded,
        accent: Color(0xFFD97706),
        proofPoints: ['Zorunlu deneme yok', 'İstediğin zaman iptal'],
      ),
    ],
  );
}
