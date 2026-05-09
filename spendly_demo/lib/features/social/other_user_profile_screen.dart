import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final otherUserProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, username, streak_count, last_active_date')
          .eq('id', userId)
          .maybeSingle();
      if (res == null) throw Exception('Kullanıcı bulunamadı');
      return res;
    });

class OtherUserProfileScreen extends ConsumerWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Profili')),
      body: profileAsync.when(
        data: (profile) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  child: Icon(Icons.person, size: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  '@${profile['username'] ?? 'Bilinmiyor'}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                if (profile['streak_count'] != null &&
                    profile['streak_count'] > 0)
                  Chip(
                    label: Text(
                      '🔥 ${profile['streak_count']} Günlük Seri',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                    backgroundColor: Colors.orange.shade50,
                  ),
                const SizedBox(height: 32),
                const Text(
                  'Bu kullanıcıyla olan ortak özellikleriniz veya gruplarınız burada görünecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Kullanıcı yüklenemedi: $e')),
      ),
    );
  }
}
