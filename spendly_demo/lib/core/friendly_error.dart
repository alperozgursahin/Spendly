import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_strings.dart';
import 'locale_provider.dart';

/// Converts a caught error into a short, non-technical message suitable for
/// showing directly to end users (SnackBar, inline error text), translated
/// via [currentAppLanguage] since this has no [WidgetRef] to read from.
///
/// Deliberately-thrown `Exception('...')` messages inside this app's service
/// classes are already written in plain Turkish, so those are unwrapped and
/// shown as-is. Anything from Supabase (auth/database) or unrecognized gets
/// a generic, friendly fallback instead of leaking raw exception text.
String friendlyErrorMessage(Object error) {
  if (error is AuthException) return _friendlyAuthMessage(error);
  if (error is PostgrestException) return _friendlyPostgrestMessage(error);

  if (error is Exception) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    if (raw.startsWith(prefix)) return raw.substring(prefix.length);
    return raw;
  }

  return AppStrings.of('error_generic_short', currentAppLanguage);
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
  }

  return AppStrings.of('error_server_generic', language);
}
