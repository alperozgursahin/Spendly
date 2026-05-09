import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_provider.dart';
import '../social/social_provider.dart';
import 'group_provider.dart';

class InviteFriendModal extends ConsumerWidget {
  final String groupId;
  const InviteFriendModal({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authClientProvider).currentUser?.id ?? '';

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Gruba Arkadaş Davet Et',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: ref
                  .read(socialServiceProvider)
                  .getAcceptedFriends(currentUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }
                final friends = snapshot.data ?? [];
                if (friends.isEmpty) {
                  return const Center(
                    child: Text('Davet edebilecek arkadaşın yok.'),
                  );
                }
                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final f = friends[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('@${f['username']}'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          try {
                            await Supabase.instance.client
                                .from('group_members')
                                .insert({
                                  'group_id': groupId,
                                  'user_id': f['id'],
                                });
                            ref.invalidate(groupMembersProvider(groupId));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Davet edildi!')),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Hata: $e')),
                              );
                          }
                        },
                        child: const Text('Ekle'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
