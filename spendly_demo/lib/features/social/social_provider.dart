import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final socialServiceProvider = Provider((ref) {
  return SocialService(Supabase.instance.client);
});

final currentUserProfileProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('No user found');

  final db = Supabase.instance.client;
  var res = await db.from('profiles').select().eq('id', userId).maybeSingle();

  if (res == null) {
    res = await db.from('profiles').insert({'id': userId}).select().single();
  }

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

      final profileFetch = await db
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', targetUserId)
          .maybeSingle();

      enrichedFriendships.add({...f, 'profiles': profileFetch});
    }
    yield enrichedFriendships;
  }
});

class SocialService {
  final SupabaseClient db;
  SocialService(this.db);

  Future<void> setUsername(String userId, String username) async {
    final existing = await db
        .from('profiles')
        .select('id')
        .eq('username', username)
        .maybeSingle();
    if (existing != null && existing['id'] != userId) {
      throw Exception('Bu kullanıcı adı çoktan alınmış.');
    }

    await db.from('profiles').update({'username': username}).eq('id', userId);
  }

  Future<void> updateProfile({
    required String currentUsername,
    required String newUsername,
    required String newEmail,
    required String avatarUrl,
  }) async {
    final user = db.auth.currentUser;
    if (user == null) throw Exception('Yetkisiz işlem');

    if (newUsername != currentUsername) {
      final existing = await db
          .from('profiles')
          .select('id')
          .eq('username', newUsername)
          .maybeSingle();
      if (existing != null && existing['id'] != user.id) {
        throw Exception('Bu kullanıcı adı çoktan alınmış.');
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
        })
        .eq('id', user.id);
  }

  Future<void> sendFriendRequest(
    String currentUserId,
    String targetUsername,
  ) async {
    final targetUser = await db
        .from('profiles')
        .select('id')
        .eq('username', targetUsername)
        .maybeSingle();
    if (targetUser == null) throw Exception('Kullanıcı bulunamadı.');

    final targetUserId = targetUser['id'];
    if (currentUserId == targetUserId)
      throw Exception('Kendinize istek gönderemezsiniz.');

    final existingQuery = await db
        .from('friendships')
        .select('id, status')
        .or(
          'and(user_id1.eq.$currentUserId,user_id2.eq.$targetUserId),and(user_id1.eq.$targetUserId,user_id2.eq.$currentUserId)',
        );

    if (existingQuery.isNotEmpty) {
      final status = existingQuery.first['status'];
      if (status == 'pending') {
        throw Exception('Zaten bekleyen bir arkadaşlık isteği var.');
      } else if (status == 'accepted') {
        throw Exception('Bu kullanıcıyla zaten arkadaşsınız.');
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
        .select('id, profiles!friendships_user_id2_fkey(id, username)')
        .eq('user_id1', currentUserId)
        .eq('status', 'accepted');
    final fetch2 = await db
        .from('friendships')
        .select('id, profiles!friendships_user_id1_fkey(id, username)')
        .eq('user_id2', currentUserId)
        .eq('status', 'accepted');

    List<Map<String, dynamic>> friends = [];
    for (var row in fetch1) {
      friends.add({
        'id': row['profiles']['id'],
        'username': row['profiles']['username'],
      });
    }
    for (var row in fetch2) {
      friends.add({
        'id': row['profiles']['id'],
        'username': row['profiles']['username'],
      });
    }
    return friends;
  }
}
