import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'core/analytics_service.dart';
import 'core/app_formatting.dart';
import 'core/experiment_service.dart';
import 'core/locale_provider.dart';
import 'core/app_theme_provider.dart';
import 'core/app_strings.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/complete_profile_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_verification_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/auth_provider.dart';
import 'features/dashboard/statistics_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/groups/group_detail_screen.dart';
import 'features/groups/group_info_screen.dart';
import 'features/groups/group_chat_screen.dart';
import 'features/groups/trip_summary_screen.dart';
import 'features/subscriptions/paywall_screen.dart';
import 'features/subscriptions/pro_tools_screen.dart';
import 'features/social/social_screen.dart';
import 'features/social/chat_screen.dart';
import 'features/social/other_user_profile_screen.dart';
import 'features/auth/update_password_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/splixa_home_screen.dart';
import 'features/profile/splixa_profile_screen.dart';
import 'main_scaffold.dart';

import 'features/subscriptions/revenuecat_config.dart';
import 'features/subscriptions/premium_provider.dart';
import 'features/subscriptions/app_lock_service.dart';
import 'features/subscriptions/home_widget_service.dart';
import 'features/subscriptions/paywall_frequency_service.dart';
import 'features/notifications/push_notification_service.dart';
import 'core/profile_preferences_service.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  factory GoRouterRefreshStream(
    Stream<dynamic> stream, {
    Listenable? listenable,
  }) {
    return GoRouterRefreshStream._(stream, listenable);
  }

  GoRouterRefreshStream._(Stream<dynamic> stream, this._listenable) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
    _listenable?.addListener(notifyListeners);
  }
  late final StreamSubscription<dynamic> _subscription;
  final Listenable? _listenable;
  @override
  void dispose() {
    _subscription.cancel();
    _listenable?.removeListener(notifyListeners);
    super.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android's release asset packaging can omit dot-prefixed files even when
  // Flutter lists them as assets. Keep the local runtime configuration under
  // a non-hidden filename so release APK/AAB builds can always load it.
  await dotenv.load(fileName: 'env.config');

  await AnalyticsService.instance.initialize();
  await ExperimentService.instance.initialize();
  await AnalyticsService.instance.setExperimentContext(
    onboardingVariant: ExperimentService.instance.onboardingVariant,
    paywallVariant: ExperimentService.instance.paywallVariant,
  );
  // Date symbols for every shipped locale, so exports and notifications can
  // format for a language other than the one currently on screen.
  await AppFormat.ensureInitialized();
  final languageController = await AppLanguageNotifier.load();
  await AnalyticsService.instance.setAppLanguage(currentAppLanguage.code);
  final onboardingController = await OnboardingController.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  await AnalyticsService.instance.identifyUser(
    Supabase.instance.client.auth.currentUser?.id,
  );

  final revenueCatKey = kIsWeb
      ? ''
      : switch (defaultTargetPlatform) {
          TargetPlatform.android => RevenueCatConfig.apiKeyAndroid,
          TargetPlatform.iOS => RevenueCatConfig.apiKeyIOS,
          _ => '',
        };

  if (revenueCatKey.isNotEmpty) {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    final purchasesConfiguration = PurchasesConfiguration(revenueCatKey);
    final restoredUser = Supabase.instance.client.auth.currentUser;
    if (restoredUser != null) {
      purchasesConfiguration.appUserID = restoredUser.id;
    }
    await Purchases.configure(purchasesConfiguration);
    if (restoredUser != null) {
      try {
        final email = restoredUser.email?.trim();
        if (email != null && email.isNotEmpty) {
          await Purchases.setEmail(email);
        }
      } catch (error) {
        debugPrint('RevenueCat restored-session sync failed: $error');
      }
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        appLanguageProvider.overrideWith((ref) => languageController),
        onboardingControllerProvider.overrideWith(
          (ref) => onboardingController,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingController = ref.read(onboardingControllerProvider);
  final analytics = ref.read(analyticsServiceProvider);
  final navigationObserver = analytics.navigationObserver;

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
      listenable: onboardingController,
    ),
    observers: [if (navigationObserver != null) navigationObserver],
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final needsGoogleProfile =
          session != null && requiresGoogleProfileSetup(session.user);
      final path = state.uri.path;
      final authFlow = ref.read(authFlowStageProvider);
      final hasCompletedOnboarding = onboardingController.completed;
      final isPublicAuthRoute =
          path == '/onboarding' ||
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/verify-login' ||
          path == '/reset-password';
      final isRecoveryRoute =
          path == '/forgot-password' ||
          path == '/verify-login' ||
          path == '/reset-password';

      // Password validation and recovery-code verification briefly create a
      // Supabase session. Never treat those temporary sessions as completed
      // authentication while a verification flow is pending.
      if (authFlow != AuthFlowStage.none && isPublicAuthRoute) return null;
      // Onboarding completion is persisted locally. A first-time install is
      // always introduced to Splixa before entering the app, while a restored
      // session on a returning install goes straight to the dashboard.
      if (!hasCompletedOnboarding &&
          path != '/onboarding' &&
          !isRecoveryRoute) {
        return '/onboarding';
      }
      if (isAuth && needsGoogleProfile && path != '/complete-profile') {
        return '/complete-profile';
      }
      if (isAuth && !needsGoogleProfile && path == '/complete-profile') {
        return '/dashboard';
      }
      // `?replay=1` is how a user deliberately returns to the intro (the back
      // arrow on the login screen). Without it, navigating to /onboarding after
      // completion bounces straight back and the button looks broken.
      final isOnboardingReplay =
          state.uri.queryParameters['replay'] == '1' && !isAuth;
      if (hasCompletedOnboarding &&
          path == '/onboarding' &&
          !isOnboardingReplay) {
        return isAuth ? '/dashboard' : '/login';
      }
      if (!isAuth && !isPublicAuthRoute) return '/login';
      if (isAuth && isPublicAuthRoute) {
        return hasCompletedOnboarding ? '/dashboard' : '/onboarding';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        name: 'complete_profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-login',
        name: 'verify_login',
        builder: (context, state) =>
            LoginVerificationScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset_password',
        builder: (context, state) =>
            ResetPasswordScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/update-password',
        name: 'update_password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const SplixaHomeScreen(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/debts',
            name: 'debts',
            builder: (context, state) => const DebtsScreen(),
          ),
          GoRoute(
            path: '/groups',
            name: 'groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'group_detail',
                builder: (context, state) {
                  final groupId = state.pathParameters['id']!;
                  final groupName =
                      state.extra as String? ??
                      AppStrings.of(
                        'route_fallback_group_detail',
                        currentAppLanguage,
                      );
                  return GroupDetailScreen(
                    groupId: groupId,
                    groupName: groupName,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'info',
                    name: 'group_info',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      final groupName =
                          state.extra as String? ??
                          AppStrings.of(
                            'route_fallback_group_info',
                            currentAppLanguage,
                          );
                      return GroupInfoScreen(
                        groupId: groupId,
                        groupName: groupName,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'chat',
                    name: 'group_chat',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      final groupName =
                          state.extra as String? ??
                          AppStrings.of(
                            'route_fallback_group',
                            currentAppLanguage,
                          );
                      return GroupChatScreen(
                        groupId: groupId,
                        groupName: groupName,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/social',
            name: 'social',
            builder: (context, state) => const SocialScreen(),
            routes: [
              GoRoute(
                path: 'chat/:id',
                name: 'direct_chat',
                builder: (context, state) {
                  final targetUserId = state.pathParameters['id']!;
                  final username =
                      state.extra as String? ??
                      AppStrings.of('route_fallback_chat', currentAppLanguage);
                  return ChatScreen(
                    targetUserId: targetUserId,
                    username: username,
                  );
                },
              ),
              GoRoute(
                path: 'user/:id',
                name: 'user_profile',
                builder: (context, state) {
                  return OtherUserProfileScreen(
                    userId: state.pathParameters['id']!,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const SplixaProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/paywall',
        name: 'paywall',
        builder: (context, state) => PaywallScreen(
          source: PaywallSource.fromAnalyticsValue(
            state.uri.queryParameters['source'],
          ),
        ),
      ),
      // Deliberately a top-level route rather than a child of /dashboard.
      // The ShellRoute owns a single Navigator GlobalKey, so pushing a route
      // that lives inside the shell while the top of the stack is outside it
      // (Pro tools -> "Advanced analytics") would mount that same key twice and
      // the navigation would fail outright. Statistics never shows the primary
      // bottom navigation anyway, so it gains nothing from the shell.
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/pro-tools',
        name: 'pro_tools',
        builder: (context, state) => const ProToolsScreen(),
      ),
      GoRoute(
        path: '/trip-summary/:id',
        name: 'trip_summary',
        builder: (context, state) => TripSummaryScreen(
          groupId: state.pathParameters['id']!,
          groupName:
              state.extra as String? ??
              AppStrings.of('route_fallback_group', currentAppLanguage),
        ),
      ),
    ],
  );
});

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  static const _brandColor = Color(0xFF0E7490);

  // Dark surfaces stay in the same slate family as the light theme's
  // secondary color (#1F2937) instead of pure black, so cards/inputs read as
  // one tonal family with the brand teal in both modes.
  static const _darkScaffold = Color(0xFF0F172A);
  static const _darkSurface = Color(0xFF1E293B);
  static const _darkBorder = Color(0xFF334155);
  String? _trackedLanguage;
  bool? _trackedProState;
  String? _runtimeUserId;
  StreamSubscription<Uri?>? _homeWidgetClickSubscription;

  @override
  void initState() {
    super.initState();
    _homeWidgetClickSubscription = SplixaHomeWidgetService.clicks.listen(
      _handleHomeWidgetClick,
    );
    unawaited(
      SplixaHomeWidgetService.initiallyLaunched().then(_handleHomeWidgetClick),
    );
  }

  void _handleHomeWidgetClick(Uri? uri) {
    if (uri == null || !mounted) return;
    final router = ref.read(routerProvider);
    if (ref.read(premiumProvider)) {
      router.go('/dashboard?quickAdd=1');
    } else {
      router.push('/paywall?source=${PaywallSource.homeWidget.analyticsValue}');
    }
  }

  @override
  void dispose() {
    _homeWidgetClickSubscription?.cancel();
    super.dispose();
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      textTheme: isDark
          ? GoogleFonts.interTextTheme(
              ThemeData(brightness: Brightness.dark).textTheme,
            )
          : GoogleFonts.interTextTheme(),
      // Only pin `primary`/`secondary` to the exact brand hex for light mode.
      // Forcing that same (fairly dark) teal as `primary` in dark mode too
      // was making primary-colored text/icons (e.g. the date-range button)
      // low-contrast against the dark background — letting `fromSeed` derive
      // its own lighter dark-mode tone from the same seed fixes that while
      // keeping both modes visibly "the same brand".
      colorScheme: isDark
          ? ColorScheme.fromSeed(seedColor: _brandColor, brightness: brightness)
          : ColorScheme.fromSeed(
              seedColor: _brandColor,
              brightness: brightness,
              primary: _brandColor,
              secondary: const Color(0xFF1F2937),
            ),
      scaffoldBackgroundColor: isDark ? _darkScaffold : const Color(0xFFF8FAFC),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? _darkScaffold : const Color(0xFFF8FAFC),
        elevation: 0.0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white70 : Colors.black87,
        ),
        titleTextStyle: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
        color: isDark ? _darkSurface : Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: isDark ? _darkBorder : Colors.grey.shade200,
            width: 0.6,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // In dark mode this needs to read as a distinct field, not just
        // match the card behind it (unlike light mode, where grey.shade100
        // already contrasts against a white card) — so it uses the lighter
        // `_darkBorder` tone instead of `_darkSurface`.
        fillColor: isDark ? _darkBorder : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _brandColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: isDark ? _darkSurface : Colors.white,
        selectedItemColor: isDark ? const Color(0xFF22D3EE) : _brandColor,
        unselectedItemColor: isDark ? Colors.white60 : const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final language = ref.watch(appLanguageProvider);
    final isPro = ref.watch(premiumProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (_runtimeUserId != currentUserId) {
      _runtimeUserId = currentUserId;
      if (currentUserId != null) {
        unawaited(ProfilePreferencesService.syncTimezone());
        unawaited(ref.read(pushNotificationServiceProvider).synchronize());
        unawaited(_offerPostOnboardingPaywall(currentUserId));
      }
    }

    if (_trackedLanguage != language.code) {
      _trackedLanguage = language.code;
      unawaited(
        ref.read(analyticsServiceProvider).setAppLanguage(language.code),
      );
      if (currentUserId != null) {
        unawaited(ref.read(pushNotificationServiceProvider).synchronize());
      }
    }
    if (_trackedProState != isPro) {
      _trackedProState = isPro;
      unawaited(
        ref.read(analyticsServiceProvider).setSubscriptionTier(isPro: isPro),
      );
      unawaited(SplixaHomeWidgetService.update(isPro: isPro));
    }

    return MaterialApp.router(
      title: 'Splixa',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // GlobalWidgetsLocalizations already derives direction from the locale;
      // pinning it here keeps RTL correct even if a delegate has not resolved
      // yet on the first frame after a live language switch.
      builder: (context, child) => Directionality(
        textDirection: language.textDirection,
        child: AppLockGate(child: child ?? const SizedBox.shrink()),
      ),
      routerConfig: router,
    );
  }

  Future<void> _offerPostOnboardingPaywall(String userId) async {
    if (ref.read(premiumProvider)) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || requiresGoogleProfileSetup(user)) return;
    final shouldShow = await PaywallFrequencyService.claimPostOnboarding(
      userId,
    );
    if (!shouldShow || !mounted || ref.read(premiumProvider)) return;
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted || Supabase.instance.client.auth.currentUser?.id != userId) {
      return;
    }
    ref
        .read(routerProvider)
        .push('/paywall?source=${PaywallSource.onboarding.analyticsValue}');
  }
}
