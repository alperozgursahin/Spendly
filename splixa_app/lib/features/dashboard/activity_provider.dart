import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_strings.dart';
import '../../core/locale_provider.dart';
import '../auth/auth_provider.dart';

class ActivityItem {
  final String description;
  final DateTime createdAt;
  final IconData icon;

  ActivityItem({
    required this.description,
    required this.createdAt,
    required this.icon,
  });
}

final activityProvider = FutureProvider<List<ActivityItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final language = ref.watch(appLanguageProvider);

  final supabase = Supabase.instance.client;
  List<ActivityItem> activities = [];

  try {
    final friendships = await supabase
        .from('friendships')
        .select(
          'created_at, status, profiles!friendships_user_id2_fkey(username)',
        )
        .eq('user_id1', userId)
        .eq('status', 'accepted')
        .order('created_at', ascending: false)
        .limit(3);

    for (var f in friendships) {
      final username =
          f['profiles']?['username'] ?? AppStrings.of('activity_someone', language);
      activities.add(
        ActivityItem(
          description: AppStrings.of('activity_became_friends', language)
              .replaceAll('{name}', username),
          createdAt: DateTime.parse(f['created_at']),
          icon: Icons.person_add,
        ),
      );
    }

    final gTrans = await supabase
        .from('group_transactions')
        .select('created_at, description, amount, groups(name)')
        .eq('payer_id', userId)
        .order('created_at', ascending: false)
        .limit(3);

    for (var gt in gTrans) {
      final groupName =
          gt['groups']?['name'] ?? AppStrings.of('activity_a_group', language);
      final amount = gt['amount'];
      activities.add(
        ActivityItem(
          description: AppStrings.of('activity_added_expense', language)
              .replaceAll('{group}', groupName)
              .replaceAll('{amount}', '$amount'),
          createdAt: DateTime.parse(gt['created_at']),
          icon: Icons.receipt_long,
        ),
      );
    }

    activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return activities.take(5).toList();
  } catch (e) {
    return [];
  }
});

