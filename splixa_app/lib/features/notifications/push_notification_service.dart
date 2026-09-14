import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/locale_provider.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  final service = PushNotificationService(Supabase.instance.client);
  ref.onDispose(service.dispose);
  return service;
});

class PushNotificationService {
  PushNotificationService(this._client);
  final SupabaseClient _client;
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredForUser;
  String? _registeredLanguage;
  Future<void>? _synchronizing;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> synchronize() {
    final active = _synchronizing;
    if (active != null) return active;
    final operation = _synchronize();
    _synchronizing = operation;
    return operation.whenComplete(() {
      if (identical(_synchronizing, operation)) _synchronizing = null;
    });
  }

  Future<void> _synchronize() async {
    if (!_supported) return;
    final user = _client.auth.currentUser;
    final language = currentAppLanguage.code;
    if (user == null ||
        (_registeredForUser == user.id && _registeredLanguage == language)) {
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token != null) await _upsert(token, user.id);
      await _refreshSubscription?.cancel();
      _refreshSubscription = messaging.onTokenRefresh.listen(
        (value) => _upsert(value, user.id),
        onError: (Object error) =>
            debugPrint('FCM token refresh failed: $error'),
      );
      _registeredForUser = user.id;
      _registeredLanguage = language;
    } catch (error) {
      debugPrint('Push registration deferred: $error');
    }
  }

  Future<void> _upsert(String token, String userId) async {
    if (_client.auth.currentUser?.id != userId) return;
    await _client.rpc(
      'register_push_token_v1',
      params: {
        'p_token': token,
        'p_platform': defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android',
        'p_language_code': currentAppLanguage.code,
      },
    );
  }

  void dispose() {
    _refreshSubscription?.cancel();
  }
}
