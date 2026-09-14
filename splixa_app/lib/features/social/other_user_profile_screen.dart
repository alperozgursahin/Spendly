import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_loading.dart';
import '../auth/auth_provider.dart';

final otherUserProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
      // Read through `profile_card_v1` rather than the table: this screen can
      // be opened for someone the viewer has no relationship with yet (a
      // pending friend request), and the profiles policy deliberately hides
      // those rows. The function still returns username and avatar so the
      // person renders, but grades `bio` and `created_at` by whether the
      // viewer is actually entitled to them, and reports which case applies
      // in `is_visible`.
      final rows = List<Map<String, dynamic>>.from(
        await Supabase.instance.client
            .rpc('profile_card_v1', params: {'p_user_id': userId}) as List,
      );
      if (rows.isEmpty) {
        throw const FriendlyException('social_user_not_found');
      }
      return rows.first;
    });

/// Groups you and this person are both in, plus whether you are friends.
///
/// The group intersection comes from `shared_groups_with_v1`, which reads the
/// viewer from `auth.uid()` server-side rather than taking it as an argument --
/// so it can only ever answer "who do *I* share groups with", never "are these
/// two strangers connected".
final otherUserRelationProvider =
    FutureProvider.family<_Relation, String>((ref, otherUserId) async {
      final currentUserId = ref.watch(currentUserIdProvider);
      final db = Supabase.instance.client;

      final sharedGroups = await db.rpc(
        'shared_groups_with_v1',
        params: {'p_other_user_id': otherUserId},
      );

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

      return _Relation(
        sharedGroups: (sharedGroups as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList(),
        isFriend: isFriend,
      );
    });

class _Relation {
  const _Relation({required this.sharedGroups, required this.isFriend});
  final List<Map<String, dynamic>> sharedGroups;
  final bool isFriend;
}

class OtherUserProfileScreen extends ConsumerWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(otherUserProfileProvider(userId));
    final relationAsync = ref.watch(otherUserRelationProvider(userId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'other_profile_title'))),
      body: profileAsync.when(
        data: (profile) {
          final username =
              profile['username'] as String? ??
              tr(ref, 'other_profile_unknown');
          final avatarUrl = profile['avatar_url'] as String?;
          final bio = (profile['bio'] as String?)?.trim();
          final joined = DateTime.tryParse(
            profile['created_at'] as String? ?? '',
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  foregroundImage: avatarUrl?.isNotEmpty == true
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: avatarUrl?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person, size: 50),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  '@$username',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              if (joined != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _membershipLabel(ref, joined),
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(bio, style: const TextStyle(height: 1.45)),
                ),
              ],
              const SizedBox(height: 24),
              relationAsync.when(
                data: (relation) => _RelationSection(
                  relation: relation,
                  userId: userId,
                  username: username,
                ),
                loading: () =>
                    const SplixaSkeletonView(type: SplixaSkeletonType.compact),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const SplixaSkeletonView(
          type: SplixaSkeletonType.profile,
          padding: EdgeInsets.all(20),
        ),
        error: (e, st) => SplixaErrorState(
          message: friendlyErrorMessage(e),
          onRetry: () => ref.invalidate(otherUserProfileProvider(userId)),
        ),
      ),
    );
  }

  /// Whole months rounded down, because "3 months" reading as 3 the day before
  /// it becomes 4 is fine, while rounding up would claim a month that has not
  /// happened. Anything under a month gets its own phrase rather than "0".
  String _membershipLabel(WidgetRef ref, DateTime joined) {
    final days = DateTime.now().difference(joined).inDays;
    final months = (days / 30.44).floor();
    if (months < 1) return tr(ref, 'other_profile_member_new');
    if (months < 12) {
      return trp(ref, 'other_profile_member_months', {'months': '$months'});
    }
    return trp(ref, 'other_profile_member_years', {
      'years': '${months ~/ 12}',
    });
  }
}

class _RelationSection extends ConsumerWidget {
  const _RelationSection({
    required this.relation,
    required this.userId,
    required this.username,
  });

  final _Relation relation;
  final String userId;
  final String username;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final groups = relation.sharedGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(ref, 'other_profile_shared_groups_title'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 8),
        if (groups.isEmpty)
          Text(
            tr(ref, 'other_profile_no_shared_groups'),
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          // Naming the groups is the point: a bare count told you there was
          // overlap without telling you where, which is the thing you actually
          // opened this screen to find out.
          ...groups.map((group) {
            final avatarUrl = group['avatar_url'] as String?;
            final name = group['name'] as String? ?? '';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: CircleAvatar(
                radius: 18,
                foregroundImage: avatarUrl?.isNotEmpty == true
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: avatarUrl?.isNotEmpty == true
                    ? null
                    : const Icon(Icons.group_rounded, size: 18),
              ),
              title: Text(name),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/groups/${group['id']}',
                extra: name,
              ),
            );
          }),
        if (relation.isFriend) ...[
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () =>
                context.push('/social/chat/$userId', extra: username),
            icon: const Icon(Icons.message_rounded),
            label: Text(tr(ref, 'other_profile_send_message')),
          ),
        ],
      ],
    );
  }
}
