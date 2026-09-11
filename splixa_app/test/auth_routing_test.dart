import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/features/auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  User user({
    required DateTime createdAt,
    required DateTime lastSignInAt,
    Map<String, dynamic> appMetadata = const {},
    Map<String, dynamic> userMetadata = const {},
  }) {
    return User(
      id: '8e6bf59d-f70c-44fe-bd68-36258a37870f',
      appMetadata: appMetadata,
      userMetadata: userMetadata,
      aud: 'authenticated',
      createdAt: createdAt.toUtc().toIso8601String(),
      lastSignInAt: lastSignInAt.toUtc().toIso8601String(),
    );
  }

  test('recognizes a newly created Supabase identity', () {
    final now = DateTime.utc(2026, 9, 11, 12);

    expect(
      isNewSupabaseUser(
        user(createdAt: now, lastSignInAt: now.add(const Duration(seconds: 2))),
      ),
      isTrue,
    );
  });

  test('does not treat a returning identity as new', () {
    final createdAt = DateTime.utc(2026, 1, 1);

    expect(
      isNewSupabaseUser(
        user(createdAt: createdAt, lastSignInAt: DateTime.utc(2026, 9, 11)),
      ),
      isFalse,
    );
  });

  test('requires a username for an incomplete Google identity', () {
    final now = DateTime.utc(2026, 9, 12);
    final googleUser = user(
      createdAt: now,
      lastSignInAt: now,
      appMetadata: const {
        'provider': 'google',
        'providers': ['google'],
      },
      userMetadata: const {'full_name': 'Splixa User'},
    );

    expect(requiresGoogleProfileSetup(googleUser), isTrue);
  });

  test('accepts a Google identity after username completion', () {
    final now = DateTime.utc(2026, 9, 12);
    final googleUser = user(
      createdAt: now,
      lastSignInAt: now,
      appMetadata: const {'provider': 'google'},
      userMetadata: const {'username': 'splixa_user'},
    );

    expect(requiresGoogleProfileSetup(googleUser), isFalse);
  });

  test('does not apply Google profile requirements to password users', () {
    final now = DateTime.utc(2026, 9, 12);
    final passwordUser = user(
      createdAt: now,
      lastSignInAt: now,
      appMetadata: const {'provider': 'email'},
    );

    expect(requiresGoogleProfileSetup(passwordUser), isFalse);
  });
}
