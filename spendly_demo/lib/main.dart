import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/groups/groups_screen.dart';
import 'features/groups/group_detail_screen.dart';
import 'features/groups/group_info_screen.dart';
import 'features/subscriptions/paywall_screen.dart';
import 'features/social/social_screen.dart';
import 'features/social/chat_screen.dart';
import 'features/social/other_user_profile_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/auth/update_password_screen.dart';
import 'main_scaffold.dart';

// Create a provider for auth state router refresh
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

const String supabaseUrl = 'https://lbalfjhpfslvqigdmbdg.supabase.co';
const String supabaseAnonKey = 'sb_publishable_xMfTp_r3Owmzzt9733g-mw_4Q7lCb_A';
const String revenueCatApiKeyApple = 'appl_dummy_production_key_123456';
const String revenueCatApiKeyGoogle = 'goog_dummy_production_key_123456';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  if (Platform.isAndroid && revenueCatApiKeyGoogle.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(revenueCatApiKeyGoogle));
  } else if (Platform.isIOS && revenueCatApiKeyApple.isNotEmpty) {
    await Purchases.configure(PurchasesConfiguration(revenueCatApiKeyApple));
  }

  runApp(const ProviderScope(child: MyApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final isLoggingIn =
          state.uri.toString() == '/login' ||
          state.uri.toString() == '/register';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final groupId = state.pathParameters['id']!;
                  final groupName = state.extra as String? ?? 'Grup Detayı';
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
                          state.extra as String? ?? 'Grup Bilgisi';
                      return GroupInfoScreen(
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
                  final username = state.extra as String? ?? 'Sohbet';
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
            builder: (context, state) => const ProfileScreen(),
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
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        ref.read(routerProvider).go('/update-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Spendly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}
