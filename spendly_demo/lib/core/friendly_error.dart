import 'package:supabase_flutter/supabase_flutter.dart';

/// Converts a caught error into a short, Turkish, non-technical message
/// suitable for showing directly to end users (SnackBar, inline error text).
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

  return 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';
}

String _friendlyAuthMessage(AuthException error) {
  final message = error.message.toLowerCase();

  if (message.contains('invalid login credentials')) {
    return 'Kullanıcı adı veya şifre hatalı.';
  }
  if (message.contains('email not confirmed')) {
    return 'E-posta adresiniz henüz doğrulanmamış.';
  }
  if (message.contains('already registered') ||
      message.contains('user already exists')) {
    return 'Bu e-posta adresiyle zaten bir hesap var.';
  }
  if (message.contains('password') && message.contains('least')) {
    return 'Şifre çok kısa. Lütfen daha uzun bir şifre seçin.';
  }
  if (message.contains('rate limit')) {
    return 'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin.';
  }

  return 'Bir sorun oluştu. Lütfen tekrar deneyin.';
}

String _friendlyPostgrestMessage(PostgrestException error) {
  switch (error.code) {
    case '23505':
      return 'Bu kayıt zaten mevcut.';
    case '42501':
      return 'Bu işlemi yapma yetkiniz yok.';
    case 'PGRST116':
      return 'Kayıt bulunamadı.';
  }

  return 'Sunucuyla iletişimde bir sorun oluştu. Lütfen tekrar deneyin.';
}
