import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics_service.dart';
import '../../core/app_strings.dart';
import '../../core/language_selector.dart';
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
    const pages = _onboardingPages;
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
                  // Language is offered once, on the first slide: it is the
                  // one decision that changes every screen that follows, and
                  // repeating it on later slides adds friction to a flow whose
                  // only job is to get the user in.
                  if (_currentPage == 0) ...[
                    const AppLanguageButton(),
                    const SizedBox(width: 6),
                  ],
                  if (!isLastPage)
                    TextButton(
                      onPressed: _isCompleting ? null : () => _finish('skip'),
                      child: Text(tr(ref, 'onboarding_skip')),
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
                    label: isLastPage
                        ? tr(ref, 'onboarding_start_free')
                        : tr(ref, 'onboarding_continue'),
                    icon: isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    loading: _isCompleting,
                    onPressed: isLastPage
                        ? () => _finish('completed')
                        : _nextPage,
                  ),
                  if (isLastPage) ...[
                    const SizedBox(height: 10),
                    Text(
                      tr(ref, 'onboarding_no_card'),
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
    final page = _onboardingPages[index];
    ref
        .read(analyticsServiceProvider)
        .onboardingStepViewed(step: index + 1, stepName: page.analyticsName);
  }

  Future<void> _finish(String completionMethod) async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(ref, 'onboarding_persistence_error'))),
      );
    }
  }
}

class _OnboardingPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final proofPoints = page.proofKeys
        .map((key) => tr(ref, key))
        .toList(growable: false);

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
            tr(ref, '${page.keyPrefix}_eyebrow'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: page.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr(ref, '${page.keyPrefix}_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -.9,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            tr(ref, '${page.keyPrefix}_description'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          if (proofPoints.isNotEmpty) ...[
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: proofPoints
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
    required this.keyPrefix,
    required this.icon,
    required this.supportingIcon,
    required this.secondaryIcon,
    required this.accent,
    this.proofKeys = const [],
  });

  final String analyticsName;

  /// Localization key prefix; `<prefix>_eyebrow`, `_title` and `_description`
  /// are resolved from `AppStrings` so every shipped locale renders this slide.
  final String keyPrefix;
  final IconData icon;
  final IconData supportingIcon;
  final IconData secondaryIcon;
  final Color accent;
  final List<String> proofKeys;
}

/// Slide structure is locale-independent; only the copy is translated.
const _onboardingPages = <_OnboardingPageData>[
  _OnboardingPageData(
    analyticsName: 'unified_money_home',
    keyPrefix: 'onboarding_p1',
    icon: Icons.account_balance_wallet_rounded,
    supportingIcon: Icons.person_rounded,
    secondaryIcon: Icons.groups_rounded,
    accent: SplixaColors.cyan,
    proofKeys: ['onboarding_p1_proof_1', 'onboarding_p1_proof_2'],
  ),
  _OnboardingPageData(
    analyticsName: 'clear_group_splits',
    keyPrefix: 'onboarding_p2',
    icon: Icons.call_split_rounded,
    supportingIcon: Icons.receipt_long_rounded,
    secondaryIcon: Icons.done_all_rounded,
    accent: Color(0xFF7C3AED),
    proofKeys: ['onboarding_p2_proof_1', 'onboarding_p2_proof_2'],
  ),
  _OnboardingPageData(
    analyticsName: 'trusted_multi_currency',
    keyPrefix: 'onboarding_p3',
    icon: Icons.currency_exchange_rounded,
    supportingIcon: Icons.lock_clock_rounded,
    secondaryIcon: Icons.history_rounded,
    accent: Color(0xFF0284C7),
    proofKeys: ['onboarding_p3_proof_1', 'onboarding_p3_proof_2'],
  ),
  _OnboardingPageData(
    analyticsName: 'free_first_pro_value',
    keyPrefix: 'onboarding_p4',
    icon: Icons.auto_awesome_rounded,
    supportingIcon: Icons.document_scanner_rounded,
    secondaryIcon: Icons.insights_rounded,
    accent: Color(0xFFD97706),
    proofKeys: ['onboarding_p4_proof_1', 'onboarding_p4_proof_2'],
  ),
];
