import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import '../social/social_provider.dart';
import 'group_provider.dart';

class InviteFriendModal extends ConsumerStatefulWidget {
  final String groupId;
  const InviteFriendModal({super.key, required this.groupId});

  @override
  ConsumerState<InviteFriendModal> createState() => _InviteFriendModalState();
}

class _InviteFriendModalState extends ConsumerState<InviteFriendModal> {
  final _searchController = TextEditingController();
  late final Future<List<Map<String, dynamic>>> _friendsFuture;

  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';
    _friendsFuture = ref
        .read(socialServiceProvider)
        .getAcceptedFriends(currentUserId);
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addFriend(Map<String, dynamic> friend) async {
    try {
      await Supabase.instance.client.from('group_members').insert({
        'group_id': widget.groupId,
        'user_id': friend['id'],
      });
      ref.invalidate(groupMembersProvider(widget.groupId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Davet edildi!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 16,
        bottom: 32,
        left: 16,
        right: 16,
      ),
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
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Arkadaşlarında ara',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(friendlyErrorMessage(snapshot.error!)),
                  );
                }

                final friends = snapshot.data ?? [];
                if (friends.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          const Text('Davet edebilecek arkadaşın yok.'),
                          const SizedBox(height: 4),
                          Text(
                            'Önce Sosyal sekmesinden arkadaş ekle.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final query = _searchController.text.trim().toLowerCase();
                final filtered = query.isEmpty
                    ? friends
                    : friends
                          .where(
                            (f) => (f['username'] as String? ?? '')
                                .toLowerCase()
                                .contains(query),
                          )
                          .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Aramanla eşleşen arkadaş bulunamadı.'),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final f = filtered[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('@${f['username']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _addFriend(f),
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
