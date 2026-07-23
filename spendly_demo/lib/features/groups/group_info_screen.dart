import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/media_upload_service.dart';
import 'group_model.dart';
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
    final avatarUrl = groupAsync.valueOrNull?.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'group_info_title'))),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Semantics(
            button: isCreator,
            label: isCreator ? 'Change group picture' : 'Group picture',
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: isCreator
                  ? () => _changeGroupPicture(context, ref, curUserId)
                  : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundImage: avatarUrl?.isNotEmpty == true
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: avatarUrl?.isNotEmpty == true
                        ? null
                        : Icon(
                            Icons.group,
                            size: 50,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                  ),
                  if (isCreator)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        child: const Icon(
                          Icons.photo_camera_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
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
                        ? tr(ref, 'common_you')
                        : '@${m.username ?? m.userId.substring(0, 6)}';

                    final isAdminMember =
                        m.userId == groupAsync.valueOrNull?.createdBy;
                    return ListTile(
                      leading: CircleAvatar(
                        foregroundImage: m.avatarUrl?.isNotEmpty == true
                            ? NetworkImage(m.avatarUrl!)
                            : null,
                        child: m.avatarUrl?.isNotEmpty == true
                            ? null
                            : const Icon(Icons.person),
                      ),
                      title: Text(memberLabel),
                      subtitle: isAdminMember ? const Text('Admin') : null,
                      trailing: isCreator && !isMe && !isAdminMember
                          ? IconButton(
                              tooltip: 'Remove member',
                              color: Theme.of(context).colorScheme.error,
                              icon: const Icon(Icons.person_remove_outlined),
                              onPressed: () => _confirmRemoveMember(
                                context,
                                ref,
                                member: m,
                                actorId: curUserId,
                              ),
                            )
                          : null,
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
                label: Text(tr(ref, 'group_info_leave_button')),
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
                label: Text(tr(ref, 'group_info_delete_button')),
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

  Future<void> _changeGroupPicture(
    BuildContext context,
    WidgetRef ref,
    String actorId,
  ) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 86,
      requestFullMetadata: false,
    );
    if (image == null || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final publicUrl = await ref
          .read(mediaUploadServiceProvider)
          .uploadGroupAvatar(groupId: groupId, image: image);
      await ref
          .read(groupServiceProvider)
          .updateGroupAvatar(
            groupId: groupId,
            actorId: actorId,
            avatarUrl: publicUrl,
          );
      ref.invalidate(groupByIdProvider(groupId));
      ref.invalidate(userGroupsProvider);
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    } catch (error) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
    }
  }

  void _confirmRemoveMember(
    BuildContext context,
    WidgetRef ref, {
    required GroupMemberModel member,
    required String actorId,
  }) {
    final memberName = member.username?.isNotEmpty == true
        ? '@${member.username}'
        : 'this member';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '$memberName will lose access to this group and its chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              try {
                await ref
                    .read(groupServiceProvider)
                    .removeMemberAsAdmin(
                      groupId: groupId,
                      memberId: member.userId,
                      actorId: actorId,
                    );
                ref.invalidate(groupMembersProvider(groupId));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (error) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(friendlyErrorMessage(error))),
                );
              }
            },
            child: const Text('Remove'),
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
              title: Text(tr(ref, 'group_info_leave_button')),
              content: Text(
                tr(
                  ref,
                  'group_info_leave_confirm',
                ).replaceFirst('%s', groupName),
              ),
              actions: [
                TextButton(
                  onPressed: isLeaving ? null : () => Navigator.pop(ctx),
                  child: Text(tr(ref, 'common_cancel')),
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
                      : Text(tr(ref, 'group_info_leave_confirm_button')),
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
              title: Text(tr(ref, 'group_info_delete_button')),
              content: Text(
                tr(
                  ref,
                  'group_info_delete_confirm',
                ).replaceFirst('%s', groupName),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                  child: Text(tr(ref, 'common_cancel')),
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
                      : Text(tr(ref, 'common_delete')),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
