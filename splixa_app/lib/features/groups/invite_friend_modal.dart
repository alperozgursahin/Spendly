import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../../core/splixa_loading.dart';
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
      final actorId = ref.read(currentUserIdProvider);
      if (actorId == null) return;
      await ref
          .read(groupServiceProvider)
          .addMemberAsAdmin(
            groupId: widget.groupId,
            memberId: friend['id'] as String,
            actorId: actorId,
          );
      ref.invalidate(groupMembersProvider(widget.groupId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'groups_invited_snackbar'))),
        );
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr(ref, 'groups_invite_modal_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: tr(ref, 'groups_invite_search_hint'),
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _friendsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SplixaSkeletonView(
                    type: SplixaSkeletonType.list,
                    itemCount: 4,
                    padding: EdgeInsets.symmetric(vertical: 12),
                  );
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
                          Text(tr(ref, 'groups_no_friends_to_invite')),
                          const SizedBox(height: 4),
                          Text(
                            tr(ref, 'groups_no_friends_hint'),
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
                  return Center(child: Text(tr(ref, 'groups_no_search_match')));
                }

                // Everyone already in the group is shown, but inert. Hiding
                // them would leave the inviter wondering whether they simply
                // forgot to add someone; a disabled row answers that.
                final existingMemberIds = ref
                    .watch(groupMembersProvider(widget.groupId))
                    .maybeWhen(
                      data: (members) => members.map((m) => m.userId).toSet(),
                      orElse: () => <String>{},
                    );

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final f = filtered[index];
                    final avatarUrl = f['avatar_url'] as String?;
                    final alreadyMember = existingMemberIds.contains(
                      f['id'] as String,
                    );
                    return ListTile(
                      enabled: !alreadyMember,
                      leading: CircleAvatar(
                        foregroundImage: avatarUrl?.isNotEmpty == true
                            ? NetworkImage(avatarUrl!)
                            : null,
                        child: avatarUrl?.isNotEmpty == true
                            ? null
                            : const Icon(Icons.person),
                      ),
                      title: Text('@${f['username']}'),
                      trailing: alreadyMember
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  tr(ref, 'groups_already_member'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: () => _addFriend(f),
                              child: Text(tr(ref, 'common_add')),
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
