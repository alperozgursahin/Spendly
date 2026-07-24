import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';

final directMessagesStreamProvider = StreamProvider<List<Map<String, dynamic>>>(
  (ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) return Stream.value([]);

    return Supabase.instance.client
        .from('direct_messages')
        .stream(primaryKey: ['id'])
        .map(
          (events) => events
              .where(
                (event) =>
                    event['sender_id'] == currentUserId ||
                    event['receiver_id'] == currentUserId,
              )
              .toList(),
        );
  },
);

final messagesStreamProvider =
    Provider.family<AsyncValue<List<Map<String, dynamic>>>, String>((
      ref,
      targetUserId,
    ) {
      final currentUserId = ref.watch(currentUserIdProvider);
      if (currentUserId == null) return const AsyncValue.data([]);
      return ref.watch(directMessagesStreamProvider).whenData((events) {
        return events
            .where(
              (event) =>
                  (event['sender_id'] == currentUserId &&
                      event['receiver_id'] == targetUserId) ||
                  (event['sender_id'] == targetUserId &&
                      event['receiver_id'] == currentUserId),
            )
            .toList()
          ..sort(
            (a, b) => (b['created_at'] as String).compareTo(
              a['created_at'] as String,
            ),
          );
      });
    });

final unreadDirectMessagesCountProvider = Provider.family<int, String>((
  ref,
  targetUserId,
) {
  final currentUserId = ref.watch(currentUserIdProvider);
  if (currentUserId == null) return 0;
  final messages = ref.watch(messagesStreamProvider(targetUserId));
  return messages.maybeWhen(
    data: (items) => items
        .where(
          (item) =>
              item['sender_id'] == targetUserId &&
              item['receiver_id'] == currentUserId &&
              item['read_status'] != true,
        )
        .length,
    orElse: () => 0,
  );
});

Future<void> markDirectMessagesRead({
  required String senderId,
  required String receiverId,
}) {
  return Supabase.instance.client
      .from('direct_messages')
      .update({'read_status': true})
      .eq('sender_id', senderId)
      .eq('receiver_id', receiverId)
      .eq('read_status', false);
}

class ChatScreen extends ConsumerStatefulWidget {
  final String targetUserId;
  final String username;
  const ChatScreen({
    super.key,
    required this.targetUserId,
    required this.username,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgController = TextEditingController();
  bool _markingRead = false;

  @override
  void initState() {
    super.initState();

    // Force a fresh fetch whenever this screen mounts so a just-switched
    // account never shows the previous account's cached messages with this
    // same target user (see GroupDetailScreen/NotificationsScreen for the
    // same pattern).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(directMessagesStreamProvider);
      _markRead();
    });
  }

  Future<void> _markRead() async {
    if (_markingRead) return;
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;
    _markingRead = true;
    try {
      await markDirectMessagesRead(
        senderId: widget.targetUserId,
        receiverId: currentUserId,
      );
      if (mounted) {
        ref.invalidate(directMessagesStreamProvider);
      }
    } catch (error) {
      debugPrint('markDirectMessagesRead failed: $error');
    } finally {
      _markingRead = false;
    }
  }

  void _send() async {
    if (_msgController.text.trim().isEmpty) return;
    final curUserId = ref.read(currentUserProvider)?.id ?? '';

    await Supabase.instance.client.from('direct_messages').insert({
      'sender_id': curUserId,
      'receiver_id': widget.targetUserId,
      'message': _msgController.text.trim(),
    });
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final msgsAsync = ref.watch(messagesStreamProvider(widget.targetUserId));
    final curUserId = ref.watch(currentUserProvider)?.id ?? '';
    final unread = ref.watch(
      unreadDirectMessagesCountProvider(widget.targetUserId),
    );
    if (unread > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markRead();
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.username)),
      body: Column(
        children: [
          Expanded(
            child: msgsAsync.when(
              data: (msgs) {
                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index];
                    final isMe = m['sender_id'] == curUserId;
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m['message'],
                          style: TextStyle(
                            color: isMe
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
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
          Padding(
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
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
