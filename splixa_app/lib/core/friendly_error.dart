import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_strings.dart';
import 'locale_provider.dart';
import '../features/auth/native_google_auth.dart';

/// Domain failures carry a localization key instead of user-facing prose.
class FriendlyException implements Exception {
  const FriendlyException(this.key);

  final String key;

  @override
  String toString() => 'FriendlyException($key)';
}

/// Converts a caught error into a short, non-technical message suitable for
/// showing directly to end users (SnackBar, inline error text), translated
/// via [currentAppLanguage] since this has no [WidgetRef] to read from.
///
/// Deliberately-thrown `Exception('...')` messages inside this app's service
/// classes are already written in plain Turkish, so those are unwrapped and
/// shown as-is. Anything from Supabase (auth/database) or unrecognized gets
/// a generic, friendly fallback instead of leaking raw exception text.
String friendlyErrorMessage(Object error) {
  if (error is FriendlyException) {
    return AppStrings.of(error.key, currentAppLanguage);
  }
  if (error is NativeGoogleAuthException) {
    return _friendlyGoogleAuthMessage(error);
  }
  if (error is AuthException) return _friendlyAuthMessage(error);
  if (error is PostgrestException) return _friendlyPostgrestMessage(error);

  if (error is Exception) {
    return AppStrings.of('error_generic_short', currentAppLanguage);
  }

  return AppStrings.of('error_generic_short', currentAppLanguage);
}

String _friendlyGoogleAuthMessage(NativeGoogleAuthException error) {
  final key = switch (error.failure) {
    NativeGoogleAuthFailure.cancelled => 'error_google_cancelled',
    NativeGoogleAuthFailure.configuration => 'error_google_configuration',
    NativeGoogleAuthFailure.unavailable => 'error_google_unavailable',
    NativeGoogleAuthFailure.timedOut => 'error_google_timeout',
    NativeGoogleAuthFailure.missingToken ||
    NativeGoogleAuthFailure.failed => 'error_google_failed',
  };
  return AppStrings.of(key, currentAppLanguage);
}

String _friendlyAuthMessage(AuthException error) {
  final message = error.message.toLowerCase();
  final language = currentAppLanguage;

  if (message.contains('invalid login credentials')) {
    return AppStrings.of('error_invalid_credentials', language);
  }
  if (message.contains('email not confirmed')) {
    return AppStrings.of('error_email_not_confirmed', language);
  }
  if (message.contains('already registered') ||
      message.contains('user already exists')) {
    return AppStrings.of('error_email_already_registered', language);
  }
  if (message.contains('password') && message.contains('least')) {
    return AppStrings.of('error_password_too_short', language);
  }
  if (message.contains('otp') ||
      message.contains('token') ||
      message.contains('expired') ||
      message.contains('verification code') ||
      message.contains('recovery code')) {
    return AppStrings.of('auth_code_invalid_or_expired', language);
  }
  if (message.contains('rate limit')) {
    return AppStrings.of('error_rate_limited', language);
  }

  return AppStrings.of('error_auth_generic', language);
}

String _friendlyPostgrestMessage(PostgrestException error) {
  final language = currentAppLanguage;

  switch (error.code) {
    case '23505':
      return AppStrings.of('error_duplicate_record', language);
    case '42501':
      return AppStrings.of('error_forbidden', language);
    case 'PGRST116':
      return AppStrings.of('error_not_found', language);
    // plpgsql `raise exception 'CODE'` arrives as P0001 with the sentinel as
    // the message. The freemium quota triggers have raised these since Phase 4
    // and the matching strings have been translated all along, but nothing ever
    // read them: hitting the group or expense cap showed a generic server
    // fault instead of the upgrade prompt it was written for.
    case 'P0001':
      final key = _postgresSentinelKey(error.message);
      if (key != null) return AppStrings.of(key, language);
  }

  return AppStrings.of('error_server_generic', language);
}

/// Maps a `raise exception` sentinel to a localization key.
///
/// Matching is by containment because PostgREST sometimes wraps the sentinel in
/// surrounding context, and longest-first because `PRO_REQUIRED_CUSTOM_CATEGORY`
/// must not be swallowed by the shorter `PRO_REQUIRED`.
String? _postgresSentinelKey(String message) {
  const sentinels = <String, String>{
    'FREE_GROUP_LIMIT_REACHED': 'error_free_group_limit',
    'FREE_PERSONAL_EXPENSE_LIMIT_REACHED': 'error_free_personal_expense_limit',
    'TRANSACTION_OWNER_MUST_MATCH_AUTH_USER': 'error_not_authenticated',
    'UNAUTHENTICATED': 'error_not_authenticated',
    'PRO_REQUIRED_CUSTOM_CATEGORY': 'error_forbidden',
    'PRO_REQUIRED': 'error_forbidden',
  };
  for (final entry in sentinels.entries) {
    if (message.contains(entry.key)) return entry.value;
  }
  if (message.contains('INVALID_')) return 'error_generic_short';
  return null;
}
