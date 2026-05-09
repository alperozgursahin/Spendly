import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'social_provider.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final friendshipsAsync = ref.watch(friendsStreamProvider);
    final curUserId = ref.watch(authClientProvider).currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Sosyal')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '@username ile arkadaş ekle',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () async {
                    if (_searchController.text.isEmpty) return;
                    try {
                      await ref
                          .read(socialServiceProvider)
                          .sendFriendRequest(
                            curUserId,
                            _searchController.text.trim(),
                          );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İstek gönderildi!')),
                      );
                      _searchController.clear();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: friendshipsAsync.when(
              data: (friendships) {
                if (friendships.isEmpty) {
                  return const Center(child: Text('Henüz arkadaşın yok.'));
                }
                return ListView.builder(
                  itemCount: friendships.length,
                  itemBuilder: (context, index) {
                    final f = friendships[index];
                    final isSender = f['user_id1'] == curUserId;
                    final friendId = isSender ? f['user_id2'] : f['user_id1'];

                    if (f['status'] == 'pending') {
                      final username =
                          f['profiles'] != null &&
                              f['profiles']['username'] != null
                          ? '@${f['profiles']['username']}'
                          : friendId;
                      final avatarUrl = f['profiles'] != null
                          ? f['profiles']['avatar_url']
                          : null;

                      Widget getAvatar() {
                        return CircleAvatar(
                          backgroundImage:
                              avatarUrl != null &&
                                  avatarUrl.toString().isNotEmpty
                              ? NetworkImage(avatarUrl.toString())
                              : null,
                          child:
                              avatarUrl == null || avatarUrl.toString().isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        );
                      }

                      if (isSender) {
                        return ListTile(
                          leading: getAvatar(),
                          title: Text('İstek gönderildi: $username'),
                          subtitle: const Text('Bekleniyor...'),
                        );
                      } else {
                        return ListTile(
                          leading: getAvatar(),
                          title: Text('Sana istek: $username'),
                          trailing: IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => ref
                                .read(socialServiceProvider)
                                .acceptFriendRequest(f['id']),
                          ),
                        );
                      }
                    }

                    if (f['status'] == 'accepted') {
                      final username =
                          f['profiles'] != null &&
                              f['profiles']['username'] != null
                          ? '@${f['profiles']['username']}'
                          : friendId;
                      final avatarUrl = f['profiles'] != null
                          ? f['profiles']['avatar_url']
                          : null;

                      Widget getAvatar() {
                        return CircleAvatar(
                          backgroundImage:
                              avatarUrl != null &&
                                  avatarUrl.toString().isNotEmpty
                              ? NetworkImage(avatarUrl.toString())
                              : null,
                          child:
                              avatarUrl == null || avatarUrl.toString().isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        );
                      }

                      return ListTile(
                        leading: GestureDetector(
                          onTap: () => context.push('/social/user/$friendId'),
                          child: getAvatar(),
                        ),
                        title: Text('Arkadaş: $username'),
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            context.push(
                              '/social/chat/$friendId',
                              extra: 'Arkadaş',
                            );
                          },
                        ),
                        onTap: () {
                          context.push('/social/user/$friendId');
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
              error: (e, st) => Center(child: Text('Hata: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }
}
