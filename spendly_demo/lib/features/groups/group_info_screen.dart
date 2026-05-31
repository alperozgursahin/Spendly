import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'group_provider.dart';
import '../auth/auth_provider.dart';

class GroupInfoScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const GroupInfoScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final curUserId = ref.watch(authClientProvider).currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Grup Bilgisi')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.group, size: 50, color: Colors.deepPurple),
          ),
          const SizedBox(height: 16),
          Text(
            groupName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Divider(),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    final isMe = m.userId == curUserId;
                    final memberLabel = isMe
                        ? 'Sen'
                        : '@${m.username ?? m.userId.substring(0, 6)}';

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(memberLabel),
                    );
                  },
                );
              },
              error: (e, st) => Center(child: Text('Hata: $e')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                // Gruptan ayrıl
                // TODO: groupServiceProvider -> leaveGroup implementation
                context.go('/groups');
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Gruptan Ayrıl'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
                backgroundColor: Colors.red.shade50,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
