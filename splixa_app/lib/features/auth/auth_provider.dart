import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics_service.dart';
import '../dashboard/activity_provider.dart';
import '../dashboard/heatmap_provider.dart';
import '../filters/filters_provider.dart';
import '../groups/group_provider.dart';
import '../notifications/notification_provider.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/currency_provider.dart';
import '../transactions/transaction_provider.dart';
import '../social/chat_screen.dart';
import '../social/other_user_profile_screen.dart';
import '../social/social_provider.dart'
    show currentUserProfileProvider, friendsStreamProvider;
import '../subscriptions/premium_provider.dart'
    show offeringsProvider, premiumProvider;
import 'native_google_auth.dart';

final authClientProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authClientProvider).onAuthStateChange;
});

enum AuthFlowStage { none, nativeSignIn, loginVerification, passwordRecovery }

final authFlowStageProvider = StateProvider<AuthFlowStage>((ref) {
  return AuthFlowStage.none;
});

final googleAuthClientProvider = Provider<GoogleAuthClient>((ref) {
  return NativeGoogleAuthClient();
});

// `authClientProvider` always resolves to the same GoTrueClient instance, so
// invalidating it doesn't notify anything watching `.currentUser` off of it —
// Riverpod skips the rebuild because the returned value is `==` to the last
// one. Providers that need to react to login/logout should watch this
// instead: it derives from `authStateProvider`, whose AsyncValue genuinely
// changes on every auth event, so dependents recompute reliably right when
// a new session starts (not just when something remembers to invalidate them).
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user.id,
    orElse: () => ref.read(authClientProvider).currentUser?.id,
  );
});

// Same rationale as `currentUserIdProvider`: derive from `authStateProvider`
// (not `authClientProvider`) so widgets watching this actually rebuild when
// the signed-in user changes. Use this instead of
// `ref.watch(authClientProvider).currentUser` anywhere the current user's
// email/metadata is needed reactively.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(
    data: (state) => state.session?.user,
    orElse: () => ref.read(authClientProvider).currentUser,
  );
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(
    Supabase.instance.client,
    ref,
    ref.watch(googleAuthClientProvider),
  );
});

class LoginStartResult {
  const LoginStartResult({required this.email, required this.requiresOtp});

  final String email;
  final bool requiresOtp;
}

class GoogleLoginResult {
  const GoogleLoginResult({required this.requiresOnboarding});

  final bool requiresOnboarding;
}

/// Supabase sets `created_at` and `last_sign_in_at` to effectively the same
/// instant when an identity is created. Existing users retain their original
/// creation timestamp, including when Google is linked on a later login.
bool isNewSupabaseUser(User user) {
  final createdAt = DateTime.tryParse(user.createdAt)?.toUtc();
  final lastSignInAt = DateTime.tryParse(user.lastSignInAt ?? '')?.toUtc();
  if (createdAt == null || lastSignInAt == null) return false;

  return lastSignInAt.difference(createdAt).abs() <=
      const Duration(seconds: 30);
}

class AccountDeletionException implements Exception {
  const AccountDeletionException({
    required this.code,
    required this.message,
    this.groupNames = const [],
  });

  final String code;
  final String message;
  final List<String> groupNames;

  @override
  String toString() => message;
}

class AuthController {
  final SupabaseClient _client;
  final Ref _ref;
  final GoogleAuthClient _googleAuth;

  AuthController(this._client, this._ref, this._googleAuth);

  /// Uses the platform-native Google account picker, then exchanges Google's
  /// short-lived tokens for a normal Supabase session. Tokens are never
  /// persisted or logged by the app.
  Future<GoogleLoginResult> signInWithGoogle() async {
    _ref.read(authFlowStageProvider.notifier).state =
        AuthFlowStage.nativeSignIn;

    try {
      final googleTokens = await _googleAuth.authenticate();
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleTokens.idToken,
        accessToken: googleTokens.accessToken,
      );

      final user = response.user;
      if (response.session == null || user == null) {
        throw const AuthException(
          'Native Google sign-in did not create a valid session.',
        );
      }

      final onboarding = _ref.read(onboardingControllerProvider);
      final requiresOnboarding =
          isNewSupabaseUser(user) && !onboarding.completedThisRun;
      if (requiresOnboarding) {
        await onboarding.reset();
      }

      await _identifyRevenueCatUser();
      await _ref
          .read(analyticsServiceProvider)
          .login(method: AnalyticsLoginMethod.google);
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
      return GoogleLoginResult(requiresOnboarding: requiresOnboarding);
    } catch (_) {
      if (_client.auth.currentSession == null) {
        try {
          await _googleAuth.signOut();
        } catch (_) {}
      }
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
      rethrow;
    }
  }

  Future<LoginStartResult> beginTwoStepSignIn({
    required String identifier,
    required String password,
  }) async {
    _ref.read(authFlowStageProvider.notifier).state =
        AuthFlowStage.loginVerification;

    try {
      final response = await _client.functions.invoke(
        'login-handler',
        body: {'identifier': identifier.trim(), 'password': password},
      );
      final data = response.data;
      if (data is! Map || data['email'] is! String) {
        throw const AuthException(
          'Secure login service returned an invalid response.',
        );
      }
      final email = (data['email'] as String).trim().toLowerCase();
      if (email.isEmpty) {
        throw const AuthException(
          'Secure login service returned an invalid response.',
        );
      }

      final reviewRefreshToken = data['reviewRefreshToken'];
      if (reviewRefreshToken is String && reviewRefreshToken.isNotEmpty) {
        final authResponse = await _client.auth.setSession(reviewRefreshToken);
        if (authResponse.session == null) {
          throw const AuthException(
            'Secure review session could not be established.',
          );
        }
        await _identifyRevenueCatUser();
        await _ref
            .read(analyticsServiceProvider)
            .login(method: AnalyticsLoginMethod.password);
        if (data['reviewAccess'] == true) {
          _ref.read(premiumProvider.notifier).grantReviewAccess();
        }
        _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
        return LoginStartResult(email: email, requiresOtp: false);
      }

      return LoginStartResult(email: email, requiresOtp: true);
    } on FunctionException catch (error) {
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
      if (error.status == 401) {
        throw const AuthException('Invalid login credentials');
      }
      if (error.status == 429) {
        throw const AuthException(
          'Too many login attempts. Please try again later.',
        );
      }
      throw const AuthException('Secure login service is unavailable.');
    } catch (_) {
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
      rethrow;
    }
  }

  Future<void> verifyLoginOtp({
    required String email,
    required String code,
  }) async {
    _ref.read(authFlowStageProvider.notifier).state =
        AuthFlowStage.loginVerification;
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.email,
      );
      if (response.session == null) {
        throw const AuthException(
          'The verification code is invalid or expired.',
        );
      }
      await _identifyRevenueCatUser();
      await _ref
          .read(analyticsServiceProvider)
          .login(method: AnalyticsLoginMethod.password);
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final normalizedUsername = username
        .trim()
        .replaceFirst(RegExp(r'^@'), '')
        .toLowerCase();
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'username': normalizedUsername},
    );
    if (response.session != null) {
      await _identifyRevenueCatUser();
    }
  }

  Future<void> _identifyRevenueCatUser() async {
    if (kIsWeb) return;
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _ref.read(premiumProvider.notifier).identifyUser(user);
    } catch (error) {
      debugPrint('RevenueCat user identification failed: $error');
    }
  }

  Future<void> resetPassword({required String email}) async {
    _ref.read(authFlowStageProvider.notifier).state =
        AuthFlowStage.passwordRecovery;
    try {
      await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
    } catch (_) {
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
      rethrow;
    }
  }

  Future<void> recoverPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    _ref.read(authFlowStageProvider.notifier).state =
        AuthFlowStage.passwordRecovery;
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: code.trim(),
        type: OtpType.recovery,
      );
      if (response.session == null) {
        throw const AuthException('The recovery code is invalid or expired.');
      }

      await _client.auth.updateUser(UserAttributes(password: newPassword));
      await _client.auth.signOut(scope: SignOutScope.local);
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
    } catch (_) {
      if (_client.auth.currentSession != null) {
        await _client.auth.signOut(scope: SignOutScope.local);
      }
      _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
      rethrow;
    }
  }

  Future<void> cancelPendingAuthFlow() async {
    if (_client.auth.currentSession != null) {
      await _client.auth.signOut(scope: SignOutScope.local);
    }
    _ref.read(authFlowStageProvider.notifier).state = AuthFlowStage.none;
  }

  // Uses the controller's own long-lived `_ref` rather than a screen's
  // WidgetRef: signing out triggers an immediate router redirect that can
  // unmount the calling screen mid-flight, which would throw on any
  // invalidate() call made after that point via a widget-bound ref — silently
  // aborting the rest of the cleanup and leaving stale data cached for the
  // next account that logs in.
  Future<void> signOut() async {
    final outgoingUserId = _client.auth.currentUser?.id;

    // Tear down the real session and third-party SDK state *before*
    // invalidating providers, so nothing can refetch the outgoing user's
    // data into a provider cache during the invalidation window.
    await _client.auth.signOut();

    await _clearLocalAccountState(outgoingUserId);
  }

  Future<void> deleteAccount() async {
    final outgoingUserId = _client.auth.currentUser?.id;
    if (outgoingUserId == null) {
      throw const AccountDeletionException(
        code: 'UNAUTHORIZED',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.functions.invoke(
        'delete-account',
        body: const {'confirmation': 'DELETE'},
      );
      final data = response.data;
      if (data is! Map || data['deleted'] != true) {
        throw const AccountDeletionException(
          code: 'INVALID_RESPONSE',
          message: 'The deletion service returned an invalid response.',
        );
      }
    } on FunctionException catch (error) {
      throw _accountDeletionExceptionFrom(error);
    }

    // The server has hard-deleted the Auth user, so only local sign-out is
    // required. This clears Supabase's persisted access and refresh tokens
    // without making a second network request for an account that no longer
    // exists.
    await _client.auth.signOut(scope: SignOutScope.local);
    await _clearLocalAccountState(outgoingUserId, resetOnboarding: true);
  }

  AccountDeletionException _accountDeletionExceptionFrom(
    FunctionException error,
  ) {
    dynamic details = error.details;
    if (details is String) {
      try {
        details = jsonDecode(details);
      } catch (_) {}
    }

    dynamic errorBody = details;
    if (details is Map && details['error'] is Map) {
      errorBody = details['error'];
    }
    if (errorBody is Map) {
      final groups = errorBody['groups'];
      final groupNames = groups is List
          ? groups
                .whereType<Map>()
                .map((group) => group['name']?.toString().trim() ?? '')
                .where((name) => name.isNotEmpty)
                .toList(growable: false)
          : const <String>[];
      return AccountDeletionException(
        code: errorBody['code']?.toString() ?? 'DELETION_FAILED',
        message:
            errorBody['message']?.toString() ??
            'Account deletion could not be completed.',
        groupNames: groupNames,
      );
    }

    return const AccountDeletionException(
      code: 'DELETION_FAILED',
      message: 'Account deletion could not be completed. Please try again.',
    );
  }

  Future<void> _clearLocalAccountState(
    String? outgoingUserId, {
    bool resetOnboarding = false,
  }) async {
    try {
      await _googleAuth.signOut();
    } catch (_) {}

    try {
      await Purchases.logOut();
    } catch (_) {}

    if (outgoingUserId != null) {
      await NotificationCursorStorage.clearCursor(outgoingUserId);
    }
    await CurrencyNotifier.clearPersistedCurrency();
    if (resetOnboarding) {
      await _ref.read(onboardingControllerProvider).reset();
    }

    _ref.invalidate(authStateProvider);
    _ref.invalidate(authClientProvider);
    _ref.invalidate(currencyProvider);
    _ref.invalidate(transactionFilterProvider);
    _ref.invalidate(groupDataRefreshProvider);
    _ref.invalidate(userGroupsProvider);
    _ref.invalidate(groupMembersProvider);
    _ref.invalidate(groupExpensesStreamProvider);
    _ref.invalidate(groupBalancesProvider);
    _ref.invalidate(groupSettlementsProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(activityProvider);
    _ref.invalidate(heatmapRangeProvider);
    _ref.invalidate(currentUserProfileProvider);
    _ref.invalidate(friendsStreamProvider);
    _ref.invalidate(directMessagesStreamProvider);
    _ref.invalidate(messagesStreamProvider);
    _ref.invalidate(otherUserProfileProvider);
    _ref.invalidate(userNotificationsProvider);
    _ref.invalidate(premiumProvider);
    _ref.invalidate(offeringsProvider);
    _ref.read(premiumProvider.notifier).reset();
  }
}
