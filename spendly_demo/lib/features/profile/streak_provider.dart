import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_provider.dart';

final streakProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authClientProvider).currentUser;
  if (user == null) return 0;

  final db = Supabase.instance.client;

  // Get current profile
  final profile = await db
      .from('profiles')
      .select('streak_count, last_active_date')
      .eq('id', user.id)
      .maybeSingle();
  if (profile == null) return 0;

  final lastActive = profile['last_active_date'] as String?;
  int currentStreak = profile['streak_count'] ?? 0;

  final now = DateTime.now().toUtc();
  final todayStr =
      "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

  if (lastActive == todayStr) {
    // Already updated today
    return currentStreak;
  }

  if (lastActive != null) {
    final lastActiveDate = DateTime.parse(lastActive);
    final diff = DateTime(now.year, now.month, now.day)
        .difference(
          DateTime(
            lastActiveDate.year,
            lastActiveDate.month,
            lastActiveDate.day,
          ),
        )
        .inDays;

    if (diff == 1) {
      // Logged in yesterday, increment
      currentStreak += 1;
    } else if (diff > 1) {
      // Missed a day, reset
      currentStreak = 1;
    }
  } else {
    // First time
    currentStreak = 1;
  }

  // Update DB
  await db
      .from('profiles')
      .update({'streak_count': currentStreak, 'last_active_date': todayStr})
      .eq('id', user.id);

  return currentStreak;
});
