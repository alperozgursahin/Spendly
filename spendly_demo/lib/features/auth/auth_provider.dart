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

class AuthController {
  final SupabaseClient _client;
  final Ref _ref;

  AuthController(this._client, this._ref);

  Future<void> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final response = await _client.rpc(
      'get_email_by_username',
      params: {'p_username': username},
    );
    if (response == null || response.toString().isEmpty) {
      throw Exception('Bu kullanıcı adıyla eşleşen bir hesap bulunamadı.');
    }
    final email = response as String;

    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    final checkResponse = await _client.rpc(
      'check_username_exists',
      params: {'p_username': username},
    );
    if (checkResponse == true) {
      throw Exception('Bu kullanıcı adı maalesef çoktan alınmış.');
    }

    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user != null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'email': email,
      });
      await _client.auth.signOut();
    }
  }

  Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'spendly://auth-callback',
    );
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
    _ref.invalidate(messagesStreamProvider);
    _ref.invalidate(otherUserProfileProvider);
    _ref.invalidate(userNotificationsProvider);
    _ref.invalidate(premiumProvider);
    _ref.invalidate(offeringsProvider);
    _ref.read(premiumProvider.notifier).reset();
  }
}
