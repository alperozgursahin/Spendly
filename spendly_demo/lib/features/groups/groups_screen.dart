import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import '../subscriptions/premium_provider.dart';
import 'group_provider.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gruplar')),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text('Henüz bir gruba dahil değilsiniz.'),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple.shade100,
                  child: const Icon(Icons.group, color: Colors.deepPurple),
                ),
                title: Text(group.name),
                subtitle: const Text('Grup Detayları için tıklayın'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.push('/groups/${group.id}', extra: group.name);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Hata: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isPremium = ref.read(premiumProvider);
          final groupsCount = groupsAsync.value?.length ?? 0;

          if (!isPremium && groupsCount >= 2) {
            context.push('/paywall');
          } else {
            _showCreateGroupDialog(context, ref);
          }
        },
        tooltip: 'Yeni Grup Oluştur',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yeni Grup Oluştur'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Grup Adı'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                final user = ref.read(authClientProvider).currentUser;
                if (user == null) return;

                try {
                  await ref
                      .read(groupServiceProvider)
                      .createGroup(nameController.text.trim(), user.id);
                  ref.invalidate(userGroupsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Hata: $e')));
                  }
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }
}
