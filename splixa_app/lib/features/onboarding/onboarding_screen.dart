import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/analytics_service.dart';
import '../../core/app_strings.dart';
import '../../core/experiment_service.dart';
import '../../core/language_selector.dart';
import '../../core/splixa_design.dart';
import 'onboarding_art.dart';

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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final Set<int> _trackedSteps = <int>{};
  final Stopwatch _flowDuration = Stopwatch();
  late final OnboardingExperimentVariant _variant;
  late final List<_OnboardingPageData> _pages;
  int _currentPage = 0;
  int? _lastInterruptedStep;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _variant = ExperimentService.instance.onboardingVariant;
    _pages = _pagesFor(_variant);
    _flowDuration.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final analytics = ref.read(analyticsServiceProvider);
      analytics.onboardingStart(variant: _variant, totalSteps: _pages.length);
      _trackStep(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flowDuration.stop();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.paused || _isCompleting) return;
    final step = _currentPage + 1;
    if (_lastInterruptedStep == step) return;
    _lastInterruptedStep = step;
    ref
        .read(analyticsServiceProvider)
        .onboardingInterrupted(
          step: step,
          totalSteps: _pages.length,
          variant: _variant,
          durationMilliseconds: _flowDuration.elapsedMilliseconds,
        );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final isLastPage = _currentPage == pages.length - 1;
    final page = pages[_currentPage];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Deliberately no top SafeArea: the accent panel runs under the status
      // bar, which is what gives the screen its full-bleed feel. The panel
      // applies the inset to its own contents instead.
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _trackStep(index);
              },
              itemBuilder: (context, index) => AnimatedBuilder(
                // Rebuilding per scroll frame is what makes the parallax track
                // the finger instead of snapping at the end of a swipe.
                animation: _pageController,
                builder: (context, child) {
                  var offset = 0.0;
                  if (_pageController.hasClients &&
                      _pageController.position.haveDimensions) {
                    offset = (_pageController.page ?? 0) - index;
                  }
                  return _OnboardingPage(
                    key: ValueKey(pages[index].analyticsName),
                    page: pages[index],
                    step: index + 1,
                    totalSteps: pages.length,
                    pageOffset: offset,
                    isActive: _currentPage == index,
                    showLanguageButton: index == 0,
                    onBack: index == 0 ? null : _previousPage,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: isLastPage
                  ? Column(
                      children: [
                        SplixaPrimaryButton(
                          label: tr(ref, 'onboarding_start_free'),
                          icon: Icons.rocket_launch_rounded,
                          loading: _isCompleting,
                          onPressed: () => _finish('completed'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          tr(ref, 'onboarding_no_card'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    )
                  // Skip left, position centre, forward right: the shape people
                  // already know from every intro flow, so the only thing they
                  // have to actually read is the slide itself.
                  // Two equal Expandeds rather than Spacers: they keep the dots
                  // optically centred while letting a long label ("Überspringen"
                  // at 320 px) shrink instead of pushing the row 40 px past the
                  // screen, which is exactly what the layout test caught.
                  : Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: _isCompleting
                                  ? null
                                  : () => _finish('skip'),
                              style: TextButton.styleFrom(
                                foregroundColor: scheme.onSurfaceVariant,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: Text(
                                tr(ref, 'onboarding_skip'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            pages.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              width: index == _currentPage ? 20 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: index == _currentPage
                                    ? page.accent
                                    : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _NextButton(
                              accent: page.accent,
                              label: tr(ref, 'onboarding_continue'),
                              onPressed: _isCompleting ? null : _nextPage,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_reduceMotion) {
      _pageController.jumpToPage(_currentPage + 1);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_reduceMotion) {
      _pageController.jumpToPage(_currentPage - 1);
    } else {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  void _trackStep(int index) {
    if (!_trackedSteps.add(index)) return;
    final page = _pages[index];
    ref
        .read(analyticsServiceProvider)
        .onboardingStepViewed(
          step: index + 1,
          stepName: page.analyticsName,
          variant: _variant,
          totalSteps: _pages.length,
        );
  }

  Future<void> _finish(String completionMethod) async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);

    try {
      await ref.read(onboardingControllerProvider).complete();
      await ref
          .read(analyticsServiceProvider)
          .onboardingComplete(
            completionMethod: completionMethod,
            variant: _variant,
            totalSteps: _pages.length,
            durationMilliseconds: _flowDuration.elapsedMilliseconds,
          );
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
    this.pageOffset = 0,
    this.isActive = true,
    this.showLanguageButton = false,
    this.onBack,
  });

  final _OnboardingPageData page;
  final int step;
  final int totalSteps;

  /// Distance from the centre of the viewport in pages: 0 is centred, -1 is one
  /// page to the left. Drives the parallax.
  final double pageOffset;

  /// Only the page the user is looking at runs its staged reveal, so a
  /// neighbour half-visible mid-swipe is never caught part-way through.
  final bool isActive;

  final bool showLanguageButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    final topInset = media?.padding.top ?? 0;
    final proofPoints = page.proofKeys
        .map((key) => tr(ref, key))
        .toList(growable: false);

    // The art gets the top ~46% of the screen and the copy the rest. Splitting
    // the screen into two solid blocks -- a coloured stage and a plain reading
    // surface -- is what makes each slide feel composed rather than like a
    // picture with text under it.
    final panelHeight = ((media?.size.height ?? 720) * 0.46).clamp(
      240.0,
      420.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: panelHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              page.accent.withValues(alpha: .34),
                              SplixaColors.slate800,
                            ]
                          : [
                              page.accent.withValues(alpha: .20),
                              page.accent.withValues(alpha: .07),
                            ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: topInset + 44, bottom: 20),
                    child: _Reveal(
                      active: isActive,
                      reduceMotion: reduceMotion,
                      delay: Duration.zero,
                      child: Transform.translate(
                        // The art drifts against the swipe at a third of the
                        // finger's speed and shrinks as it leaves. Depth
                        // without a second asset.
                        offset: Offset(reduceMotion ? 0 : -pageOffset * 110, 0),
                        child: Transform.scale(
                          scale: reduceMotion
                              ? 1
                              : (1 - (pageOffset.abs() * .10)).clamp(.82, 1.0),
                          child: Semantics(
                            label:
                                '${tr(ref, '${page.keyPrefix}_title')}. '
                                '$step / $totalSteps',
                            child: _OnboardingIllustration(
                              page: page,
                              reduceMotion: reduceMotion,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: topInset + 6,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    if (onBack != null)
                      IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).backButtonTooltip,
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: SplixaLogo(compact: true),
                      ),
                    const Spacer(),
                    // Language is offered once, on the first slide: it is the
                    // one decision that changes every screen after it.
                    if (showLanguageButton) const AppLanguageButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Reveal(
                  active: isActive,
                  reduceMotion: reduceMotion,
                  delay: const Duration(milliseconds: 90),
                  child: Text(
                    tr(ref, '${page.keyPrefix}_eyebrow').toUpperCase(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: page.accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _Reveal(
                  active: isActive,
                  reduceMotion: reduceMotion,
                  delay: const Duration(milliseconds: 150),
                  child: Text(
                    tr(ref, '${page.keyPrefix}_title'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.9,
                      height: 1.12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _Reveal(
                  active: isActive,
                  reduceMotion: reduceMotion,
                  delay: const Duration(milliseconds: 210),
                  child: Text(
                    tr(ref, '${page.keyPrefix}_description'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
                if (proofPoints.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _Reveal(
                    active: isActive,
                    reduceMotion: reduceMotion,
                    delay: const Duration(milliseconds: 280),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: proofPoints
                          .map(
                            (point) => Chip(
                              visualDensity: VisualDensity.compact,
                              avatar: Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: page.accent,
                              ),
                              label: Text(point),
                              backgroundColor: page.accent.withValues(
                                alpha: isDark ? .16 : .08,
                              ),
                              side: BorderSide(
                                color: page.accent.withValues(alpha: .24),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Circular forward button in the page accent, the way the reference flows do
/// it. Sized to the 48dp minimum touch target even though the visible disc is
/// smaller than the old full-width bar.
class _NextButton extends StatelessWidget {
  const _NextButton({
    required this.accent,
    required this.label,
    required this.onPressed,
  });

  final Color accent;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: accent,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox.square(
            dimension: 52,
            child: Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts its child into place once, shortly after the page becomes
/// the active one. Staggering these by ~60ms is what separates a screen that
/// "appears" from one that reads as composed -- and it is why the previous
/// pass, which had motion only inside the illustration, felt unfinished.
///
/// Honours the platform's reduce-motion setting by rendering the end state
/// immediately; vestibular triggers are not a style choice.
class _Reveal extends StatefulWidget {
  const _Reveal({
    required this.child,
    required this.active,
    required this.reduceMotion,
    required this.delay,
  });

  final Widget child;
  final bool active;
  final bool reduceMotion;
  final Duration delay;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _maybePlay();
  }

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) _maybePlay();
  }

  void _maybePlay() {
    if (widget.reduceMotion) {
      _controller.value = 1;
      return;
    }
    if (!widget.active) {
      _controller.value = 0;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted && widget.active) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduceMotion) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, 22 * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({
    required this.page,
    required this.reduceMotion,
  });

  final _OnboardingPageData page;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    child: OnboardingArt(
      scene: page.scene,
      accent: page.accent,
      reduceMotion: reduceMotion,
    ),
  );
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.analyticsName,
    required this.keyPrefix,
    required this.accent,
    required this.scene,
    this.proofKeys = const [],
  });

  final String analyticsName;

  /// Localization key prefix; `<prefix>_eyebrow`, `_title` and `_description`
  /// are resolved from `AppStrings` so every shipped locale renders this slide.
  final String keyPrefix;
  final Color accent;

  /// Which hand-built vector scene this slide shows. Replaced the Lottie asset
  /// path: those four files held placeholder geometry, not artwork.
  final OnboardingScene scene;
  final List<String> proofKeys;
}

/// Slide structure is locale-independent; only the copy is translated.
const _onboardingPages = <_OnboardingPageData>[
  _OnboardingPageData(
    analyticsName: 'unified_money_home',
    keyPrefix: 'onboarding_p1',
    accent: SplixaColors.cyan,
    scene: OnboardingScene.personalAndShared,
    proofKeys: ['onboarding_p1_proof_1', 'onboarding_p1_proof_2'],
  ),
  _OnboardingPageData(
    analyticsName: 'clear_group_splits',
    keyPrefix: 'onboarding_p2',
    accent: Color(0xFF7C3AED),
    scene: OnboardingScene.clearSplits,
    proofKeys: ['onboarding_p2_proof_1', 'onboarding_p2_proof_2'],
  ),
  _OnboardingPageData(
    analyticsName: 'trusted_multi_currency',
    keyPrefix: 'onboarding_p3',
    accent: Color(0xFF0284C7),
    scene: OnboardingScene.trustedCurrency,
    proofKeys: ['onboarding_p3_proof_1', 'onboarding_p3_proof_2'],
  ),
  _OnboardingPageData(
    analyticsName: 'free_first_pro_value',
    keyPrefix: 'onboarding_p4',
    accent: Color(0xFFD97706),
    scene: OnboardingScene.pro,
    proofKeys: ['onboarding_p4_proof_1', 'onboarding_p4_proof_2'],
  ),
];

List<_OnboardingPageData> _pagesFor(OnboardingExperimentVariant variant) {
  return switch (variant) {
    OnboardingExperimentVariant.control => _onboardingPages,
    OnboardingExperimentVariant.focused => [
      _onboardingPages[0],
      _onboardingPages[1],
      _onboardingPages[3],
    ],
  };
}
