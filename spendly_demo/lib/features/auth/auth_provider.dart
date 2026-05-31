import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
