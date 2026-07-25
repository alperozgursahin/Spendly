import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'core/locale_provider.dart';
import 'core/app_theme_provider.dart';
import 'core/app_strings.dart';
import 'features/auth/login_screen.dart';
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
import 'features/subscriptions/paywall_screen.dart';
import 'features/social/social_screen.dart';
import 'features/social/chat_screen.dart';
import 'features/social/other_user_profile_screen.dart';
import 'features/auth/update_password_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/splixa_home_screen.dart';
import 'features/profile/splixa_profile_screen.dart';
import 'main_scaffold.dart';

import 'features/subscriptions/revenuecat_config.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final revenueCatKey = Platform.isAndroid
      ? RevenueCatConfig.apiKeyAndroid
      : RevenueCatConfig.apiKeyIOS;

  if (revenueCatKey.isNotEmpty) {
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
    final purchasesConfiguration = PurchasesConfiguration(revenueCatKey);
    final restoredUserId = Supabase.instance.client.auth.currentUser?.id;
    if (restoredUserId != null) {
      purchasesConfiguration.appUserID = restoredUserId;
    }
    await Purchases.configure(purchasesConfiguration);
  }

  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final path = state.uri.path;
      final authFlow = ref.read(authFlowStageProvider);
      final isPublicAuthRoute =
          path == '/onboarding' ||
          path == '/login' ||
          path == '/register' ||
          path == '/forgot-password' ||
          path == '/verify-login' ||
          path == '/reset-password';

      // Password validation and recovery-code verification briefly create a
      // Supabase session. Never treat those temporary sessions as completed
      // authentication while a verification flow is pending.
      if (authFlow != AuthFlowStage.none && isPublicAuthRoute) return null;
      if (!isAuth && !isPublicAuthRoute) return '/login';
      if (isAuth && isPublicAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-login',
        builder: (context, state) =>
            LoginVerificationScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const SplixaHomeScreen(),
            routes: [
              GoRoute(
                path: 'statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/debts',
            builder: (context, state) => const DebtsScreen(),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: ':id',
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
            builder: (context, state) => const SocialScreen(),
            routes: [
              GoRoute(
                path: 'chat/:id',
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
            builder: (context, state) => const SplixaProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
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

    return MaterialApp.router(
      title: 'Splixa',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: themeMode,
      locale: Locale(language == AppLanguage.en ? 'en' : 'tr'),
      supportedLocales: const [Locale('tr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
