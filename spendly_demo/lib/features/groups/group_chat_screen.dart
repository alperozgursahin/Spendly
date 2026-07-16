import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _msgController = TextEditingController();

  // Captured so `dispose` never has to touch `ref` (unsafe once the widget
  // starts unmounting) to fire the exit-time read receipt.
  String? _userId;

  @override
  void initState() {
    super.initState();

    // See GroupDetailScreen/ChatScreen: realtime .stream() providers
    // occasionally return empty on their first subscribe. Force a fresh
    // subscribe whenever this screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(groupMessagesStreamProvider(widget.groupId));
      ref.invalidate(groupMembersProvider(widget.groupId));
      _userId = ref.read(currentUserIdProvider);
      _markRead();
    });
  }

  void _markRead() {
    final userId = _userId;
    if (userId == null) return;

    markGroupChatRead(widget.groupId, userId)
        .then((_) {
          if (mounted) {
            ref.invalidate(groupChatReadStreamProvider(widget.groupId));
          }
        })
        .catchError((error) {
          debugPrint('markGroupChatRead failed: $error');
        });
  }

  @override
  void dispose() {
    // Also mark-read on exit so messages that arrived while this screen was
    // open (and thus already visible to the user) don't count as unread.
    _markRead();
    _msgController.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    final curUserId = ref.read(currentUserProvider)?.id ?? '';
    if (curUserId.isEmpty) return;

    _msgController.clear();
    await Supabase.instance.client.from('group_messages').insert({
      'group_id': widget.groupId,
      'sender_id': curUserId,
      'message': text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgsAsync = ref.watch(groupMessagesStreamProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final curUserId = ref.watch(currentUserProvider)?.id ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    final usernamesById = <String, String>{};
    membersAsync.whenData((members) {
      for (final m in members) {
        usernamesById[m.userId] = m.username ?? tr(ref, 'common_user');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupName} ${tr(ref, 'groups_chat_suffix')}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: msgsAsync.when(
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Text(tr(ref, 'groups_chat_empty')),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final senderId = m['sender_id'] as String;
                    final isMe = senderId == curUserId;
                    final senderName =
                        usernamesById[senderId] ?? tr(ref, 'common_user');

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isMe)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  senderName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            Text(
                              m['message'] as String,
                              style: TextStyle(
                                color: isMe
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              error: (e, st) => Center(child: Text(friendlyErrorMessage(e))),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: tr(ref, 'groups_chat_input_hint'),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
