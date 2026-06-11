import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_provider.dart';

final messagesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      targetUserId,
    ) {
      final curUserId = ref.watch(authClientProvider).currentUser?.id ?? '';
      if (curUserId.isEmpty) return Stream.value([]);

      return Supabase.instance.client
          .from('direct_messages')
          .stream(primaryKey: ['id'])
          .map((events) {
            return events
                .where(
                  (e) =>
                      (e['sender_id'] == curUserId &&
                          e['receiver_id'] == targetUserId) ||
                      (e['sender_id'] == targetUserId &&
                          e['receiver_id'] == curUserId),
                )
                .toList()
              ..sort(
                (a, b) => (b['created_at'] as String).compareTo(
                  a['created_at'] as String,
                ),
              );
          });
    });

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

  void _send() async {
    if (_msgController.text.trim().isEmpty) return;
    final curUserId = ref.read(authClientProvider).currentUser?.id ?? '';

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
    final curUserId = ref.watch(authClientProvider).currentUser?.id ?? '';

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
                              ? Colors.deepPurple.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m['message']),
                      ),
                    );
                  },
                );
              },
              error: (e, st) => Center(child: Text('Hata: $e')),
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
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yaz...',
                      border: OutlineInputBorder(),
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

