import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/activity_provider.dart';
import '../dashboard/heatmap_provider.dart';
import '../filters/filters_provider.dart';
import '../groups/group_provider.dart';
import '../notifications/notification_provider.dart';
import '../profile/currency_provider.dart';
import '../transactions/transaction_provider.dart';
import '../social/chat_screen.dart';
import '../social/other_user_profile_screen.dart';
import '../social/social_provider.dart'
    show currentUserProfileProvider, friendsStreamProvider;
import '../subscriptions/premium_provider.dart'
    show offeringsProvider, premiumProvider;

final authClientProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authClientProvider).onAuthStateChange;
});

enum AuthFlowStage { none, loginVerification, passwordRecovery }

final authFlowStageProvider = StateProvider<AuthFlowStage>((ref) {
  return AuthFlowStage.none;
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
  return AuthController(Supabase.instance.client, ref);
});

class LoginStartResult {
  const LoginStartResult({required this.email, required this.requiresOtp});

  final String email;
  final bool requiresOtp;
}

class AuthController {
  final SupabaseClient _client;
  final Ref _ref;

  AuthController(this._client, this._ref);

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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Purchases.logIn(userId);
      _ref.invalidate(premiumProvider);
      _ref.invalidate(offeringsProvider);
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

    try {
      await Purchases.logOut();
    } catch (_) {}

    if (outgoingUserId != null) {
      await NotificationCursorStorage.clearCursor(outgoingUserId);
    }
    await CurrencyNotifier.clearPersistedCurrency();

    _ref.invalidate(authStateProvider);
    _ref.invalidate(authClientProvider);
    _ref.invalidate(currencyProvider);
    _ref.invalidate(transactionFilterProvider);
    _ref.invalidate(groupPaidOverridesProvider);
    _ref.invalidate(groupDataRefreshProvider);
    _ref.invalidate(userGroupsProvider);
    _ref.invalidate(groupMembersProvider);
    _ref.invalidate(groupTransactionsStreamProvider);
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
