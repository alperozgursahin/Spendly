import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/friendly_error.dart';
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
    final groupAsync = ref.watch(groupByIdProvider(groupId));
    final curUserId = ref.watch(currentUserProvider)?.id ?? '';
    final isCreator = groupAsync.maybeWhen(
      data: (group) => group != null && group.createdBy == curUserId,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Grup Bilgisi')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.group,
              size: 50,
              color: Theme.of(context).colorScheme.primary,
            ),
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
              error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          if (!isCreator)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ElevatedButton.icon(
                onPressed: () => _showLeaveGroupDialog(context, ref),
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Gruptan Ayrıl'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.red,
                  backgroundColor: Colors.red.shade50,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          if (isCreator)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteGroupDialog(context, ref),
                icon: const Icon(Icons.delete_forever),
                label: const Text('Grubu Sil'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red.shade700,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, WidgetRef ref) {
    bool isLeaving = false;
    final curUserId = ref.read(currentUserProvider)?.id;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Gruptan Ayrıl'),
              content: Text(
                '"$groupName" grubundan ayrılmak istediğinize emin misiniz? '
                'Geçmiş harcamalarınız grupta kalır.',
              ),
              actions: [
                TextButton(
                  onPressed: isLeaving ? null : () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: isLeaving || curUserId == null
                      ? null
                      : () async {
                          setState(() => isLeaving = true);
                          try {
                            await ref
                                .read(groupServiceProvider)
                                .leaveGroup(groupId, curUserId);
                            ref.invalidate(userGroupsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) context.go('/groups');
                          } catch (e) {
                            if (ctx.mounted) {
                              setState(() => isLeaving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(friendlyErrorMessage(e)),
                                ),
                              );
                            }
                          }
                        },
                  child: isLeaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ayrıl'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteGroupDialog(BuildContext context, WidgetRef ref) {
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Grubu Sil'),
              content: Text(
                '"$groupName" grubunu ve tüm harcama/üyelik verilerini '
                'kalıcı olarak silmek istediğinize emin misiniz? Bu işlem '
                'geri alınamaz.',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: const Text('İptal'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() => isDeleting = true);
                          try {
                            await ref
                                .read(groupServiceProvider)
                                .deleteGroup(groupId);
                            ref.invalidate(userGroupsProvider);
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) context.go('/groups');
                          } catch (e) {
                            if (ctx.mounted) {
                              setState(() => isDeleting = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(friendlyErrorMessage(e)),
                                ),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sil'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
