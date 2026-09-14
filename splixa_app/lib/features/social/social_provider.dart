import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/friendly_error.dart';

final socialServiceProvider = Provider((ref) {
  return SocialService(Supabase.instance.client);
});

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw const FriendlyException('error_not_found');

  final db = Supabase.instance.client;
  // Columns are listed explicitly rather than using `select()`. `profiles.email`
  // is no longer selectable by the `authenticated` role (see the
  // close_public_profile_exposure migration), so `select *` now fails outright.
  // The signed-in user's own address is already on the session anyway.
  const columns =
      'id, username, full_name, avatar_url, bio, streak_count, '
      'last_active_date, timezone, debt_reminders_enabled, updated_at';

  var res = await db
      .from('profiles')
      .select(columns)
      .eq('id', userId)
      .maybeSingle();

  res ??= await db
      .from('profiles')
      .insert({'id': userId})
      .select(columns)
      .single();

  return res;
});

final friendsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((
  ref,
) async* {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    yield [];
    return;
  }

  final db = Supabase.instance.client;

  await for (var events in db.from('friendships').stream(primaryKey: ['id'])) {
    final friendships = events
        .where((e) => e['user_id1'] == userId || e['user_id2'] == userId)
        .toList();

    List<Map<String, dynamic>> enrichedFriendships = [];
    for (var f in friendships) {
      final isSender = f['user_id1'] == userId;
      final targetUserId = isSender ? f['user_id2'] : f['user_id1'];

      // This stream carries pending requests as well as accepted friends, and
      // `can_view_profile` only counts accepted ones -- so reading the table
      // directly would render every incoming request as a blank person.
      // `profile_card_v1` returns username and avatar for anyone, which is
      // what this list shows.
      final profileRows = List<Map<String, dynamic>>.from(
        await db.rpc('profile_card_v1', params: {'p_user_id': targetUserId})
            as List,
      );
      final profileFetch = profileRows.isEmpty ? null : profileRows.first;

      enrichedFriendships.add({...f, 'profiles': profileFetch});
    }
    yield enrichedFriendships;
  }
});

// Drives the "Sosyal" bottom-nav badge: how many incoming friend requests
// are waiting on the current user (i.e. someone else sent them, they
// haven't responded yet). Outgoing pending requests don't count.
final pendingFriendRequestCountProvider = Provider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final friendships = ref.watch(friendsStreamProvider);

  return friendships.maybeWhen(
    data: (items) => items
        .where((f) => f['status'] == 'pending' && f['user_id1'] != userId)
        .length,
    orElse: () => 0,
  );
});

class SocialService {
  final SupabaseClient db;
  SocialService(this.db);

  Future<void> setUsername(String userId, String username) async {
    // `username_taken_v1` excludes the caller server-side, so re-saving an
    // unchanged username does not report the user's own name as taken.
    if (await db.rpc('username_taken_v1', params: {'p_username': username})
        == true) {
      throw const FriendlyException('profile_setup_username_taken');
    }

    await db.from('profiles').update({'username': username}).eq('id', userId);
  }

  Future<void> updateProfile({
    required String currentUsername,
    required String newUsername,
    required String newEmail,
    required String avatarUrl,
    required String bio,
  }) async {
    final user = db.auth.currentUser;
    if (user == null) throw const FriendlyException('error_forbidden');

    if (newUsername != currentUsername) {
      if (await db.rpc('username_taken_v1', params: {'p_username': newUsername})
          == true) {
        throw const FriendlyException('profile_setup_username_taken');
      }
    }

    if (newEmail != user.email) {
      await db.auth.updateUser(UserAttributes(email: newEmail));
    }

    await db
        .from('profiles')
        .update({
          'username': newUsername,
          'email': newEmail,
          'avatar_url': avatarUrl,
          'bio': bio,
        })
        .eq('id', user.id);
  }

  Future<List<Map<String, dynamic>>> searchUsers(
    String query,
    String currentUserId,
  ) async {
    final trimmed = query.trim().replaceFirst(RegExp(r'^@'), '');
    if (trimmed.isEmpty) return [];

    // Discovery goes through `search_profiles_v1` rather than the table. The
    // profiles policy now only exposes rows the viewer is entitled to see --
    // self, friends, group co-members -- so a direct `ilike` here would find
    // nobody new. The function returns identity fields only, never bio or
    // activity, and requires at least two characters.
    final rows = await db.rpc(
      'search_profiles_v1',
      params: {'p_query': trimmed},
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> sendFriendRequest(
    String currentUserId,
    String targetUsername,
  ) async {
    // Same reason as the search above: the target of a friend request is by
    // definition someone the sender cannot yet read from `profiles`. The
    // function orders exact matches first, but the match is confirmed here so
    // a substring hit can never be mistaken for the intended person.
    final wanted = targetUsername.trim().toLowerCase();
    final candidates = List<Map<String, dynamic>>.from(
      await db.rpc('search_profiles_v1', params: {'p_query': targetUsername})
          as List,
    );
    Map<String, dynamic>? targetUser;
    for (final row in candidates) {
      if ((row['username'] as String?)?.trim().toLowerCase() == wanted) {
        targetUser = row;
        break;
      }
    }
    if (targetUser == null) {
      throw const FriendlyException('social_user_not_found');
    }

    final targetUserId = targetUser['id'];
    if (currentUserId == targetUserId) {
      throw const FriendlyException('social_cannot_add_self');
    }

    final existingQuery = await db
        .from('friendships')
        .select('id, status')
        .or(
          'and(user_id1.eq.$currentUserId,user_id2.eq.$targetUserId),and(user_id1.eq.$targetUserId,user_id2.eq.$currentUserId)',
        );

    if (existingQuery.isNotEmpty) {
      final status = existingQuery.first['status'];
      if (status == 'pending') {
        throw const FriendlyException('social_request_already_pending');
      } else if (status == 'accepted') {
        throw const FriendlyException('social_already_friends');
      }
    }

    await db.from('friendships').insert({
      'user_id1': currentUserId,
      'user_id2': targetUserId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await db
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('id', friendshipId);
  }

  Future<List<Map<String, dynamic>>> getAcceptedFriends(
    String currentUserId,
  ) async {
    final fetch1 = await db
        .from('friendships')
        .select('id, profiles!friendships_user_id2_fkey(id, username, avatar_url)')
        .eq('user_id1', currentUserId)
        .eq('status', 'accepted');
    final fetch2 = await db
        .from('friendships')
        .select('id, profiles!friendships_user_id1_fkey(id, username, avatar_url)')
        .eq('user_id2', currentUserId)
        .eq('status', 'accepted');

    final friendsById = <String, Map<String, dynamic>>{};
    for (var row in fetch1) {
      final id = row['profiles']['id'] as String;
      friendsById[id] = {
        'id': id,
        'username': row['profiles']['username'],
        'avatar_url': row['profiles']['avatar_url'],
      };
    }
    for (var row in fetch2) {
      final id = row['profiles']['id'] as String;
      friendsById[id] = {
        'id': id,
        'username': row['profiles']['username'],
        'avatar_url': row['profiles']['avatar_url'],
      };
    }
    return friendsById.values.toList();
  }
}
