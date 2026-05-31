import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final authClient = ref.watch(authClientProvider);
  final userId = authClient.currentUser?.id;
  if (userId == null) return [];

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
      final username = f['profiles']?['username'] ?? 'Biri';
      activities.add(
        ActivityItem(
          description: '$username ile arkadaş oldun.',
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
      final groupName = gt['groups']?['name'] ?? 'Bir grup';
      final amount = gt['amount'];
      activities.add(
        ActivityItem(
          description: '$groupName grubunda $amount₺ harcama ekledin.',
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
