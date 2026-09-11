import 'package:flutter_test/flutter_test.dart';
import 'package:splixa_app/features/auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  User user({required DateTime createdAt, required DateTime lastSignInAt}) {
    return User(
      id: '8e6bf59d-f70c-44fe-bd68-36258a37870f',
      appMetadata: const {},
      userMetadata: const {},
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
}
