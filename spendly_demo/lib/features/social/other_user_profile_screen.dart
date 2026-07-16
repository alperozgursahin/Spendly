import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';

final otherUserProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('id, username')
          .eq('id', userId)
          .maybeSingle();
      if (res == null) throw Exception('Kullanıcı bulunamadı');
      return res;
    });

// Real content for what used to be a placeholder screen: how many groups
// this user shares with you, and whether you're already friends (RLS on
// group_members/friendships already scopes results to rows the current
// user is allowed to see, so this doubles as the intersection query).
final otherUserRelationProvider =
    FutureProvider.family<Map<String, dynamic>, String>((
      ref,
      otherUserId,
    ) async {
      final currentUserId = ref.watch(currentUserIdProvider);
      final db = Supabase.instance.client;

      final sharedGroupRows = await db
          .from('group_members')
          .select('group_id')
          .eq('user_id', otherUserId);

      var isFriend = false;
      if (currentUserId != null) {
        final friendshipRows = await db
            .from('friendships')
            .select('status')
            .or(
              'and(user_id1.eq.$currentUserId,user_id2.eq.$otherUserId),'
              'and(user_id1.eq.$otherUserId,user_id2.eq.$currentUserId)',
            );
        isFriend = friendshipRows.any((row) => row['status'] == 'accepted');
      }

      return {
        'sharedGroupsCount': sharedGroupRows.length,
        'isFriend': isFriend,
      };
    });

class OtherUserProfileScreen extends ConsumerWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId));
    final relationAsync = ref.watch(otherUserRelationProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'other_profile_title'))),
      body: profileAsync.when(
        data: (profile) {
          final username =
              profile['username'] as String? ?? tr(ref, 'other_profile_unknown');

          return Center(
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
                    '@$username',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  relationAsync.when(
                    data: (relation) {
                      final sharedGroupsCount =
                          relation['sharedGroupsCount'] as int;
                      final isFriend = relation['isFriend'] as bool;

                      return Column(
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.group,
                                    size: 20,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    sharedGroupsCount == 0
                                        ? tr(
                                            ref,
                                            'other_profile_no_shared_groups',
                                          )
                                        : tr(
                                            ref,
                                            'other_profile_shared_groups_count',
                                          ).replaceFirst(
                                            '%s',
                                            '$sharedGroupsCount',
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isFriend) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                context.push(
                                  '/social/chat/$userId',
                                  extra: username,
                                );
                              },
                              icon: const Icon(Icons.message),
                              label: Text(tr(ref, 'other_profile_send_message')),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () =>
                        const CircularProgressIndicator(strokeWidth: 2),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
      ),
    );
  }
}
