import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import '../subscriptions/premium_provider.dart';
import 'group_provider.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  void initState() {
    super.initState();

    // Force a fresh fetch whenever this screen mounts so groups another
    // member added you to (or a just-switched account's groups) show up
    // without needing an unrelated action like creating a new group first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(userGroupsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Gruplar')),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Henüz bir gruba dahil değilsiniz.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sağ alttaki + butonuna dokunarak ilk grubunu '
                      'oluşturabilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.group,
                    color: Theme.of(context).colorScheme.primary,
                  ),
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
        error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
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

                final user = ref.read(currentUserProvider);
                if (user == null) return;

                try {
                  await ref
                      .read(groupServiceProvider)
                      .createGroup(nameController.text.trim(), user.id);
                  ref.invalidate(userGroupsProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(friendlyErrorMessage(e))),
                    );
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
