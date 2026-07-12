import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/activity_provider.dart';
import '../filters/filters_provider.dart';
import '../groups/group_provider.dart';
import '../notifications/notification_provider.dart';
import '../profile/currency_provider.dart';
import '../social/chat_screen.dart';
import '../social/other_user_profile_screen.dart';
import '../social/social_provider.dart' show currentUserProfileProvider, friendsStreamProvider;
import '../subscriptions/premium_provider.dart' show offeringsProvider, premiumProvider;

final authClientProvider = Provider<GoTrueClient>((ref) {
  return Supabase.instance.client.auth;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authClientProvider).onAuthStateChange;
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(Supabase.instance.client);
});

class AuthController {
  final SupabaseClient _client;

  AuthController(this._client);

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

  Future<void> signOut(Ref ref) async {
    ref.invalidate(authStateProvider);
    ref.invalidate(authClientProvider);
    ref.invalidate(currencyProvider);
    ref.invalidate(transactionFilterProvider);
    ref.invalidate(groupPaidOverridesProvider);
    ref.invalidate(groupDataRefreshProvider);
    ref.invalidate(userGroupsProvider);
    ref.invalidate(groupMembersProvider);
    ref.invalidate(groupTransactionsStreamProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(activityProvider);
    ref.invalidate(currentUserProfileProvider);
    ref.invalidate(friendsStreamProvider);
    ref.invalidate(messagesStreamProvider);
    ref.invalidate(otherUserProfileProvider);
    ref.invalidate(userNotificationsProvider);
    ref.invalidate(premiumProvider);
    ref.invalidate(offeringsProvider);
    ref.read(premiumProvider.notifier).reset();

    await CurrencyNotifier.clearPersistedCurrency();
    await NotificationCursorStorage.clearCursor();

    try {
      await Purchases.logOut();
    } catch (_) {}

    await _client.auth.signOut();
  }
}
