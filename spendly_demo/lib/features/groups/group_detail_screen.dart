import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'group_provider.dart';
import 'group_transaction_model.dart';
import 'group_model.dart';
import 'add_expense_sheet.dart';
import 'group_info_screen.dart';
import 'invite_friend_modal.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(
      groupTransactionsStreamProvider(groupId),
    );
    final currentUserId = ref.watch(authClientProvider).currentUser?.id ?? '';
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            context.push('/groups/$groupId/info', extra: groupName);
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.deepPurple.shade100,
                radius: 18,
                child: const Icon(
                  Icons.group,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    membersAsync.when(
                      data: (members) => Text(
                        '${members.length} Katılımcı',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      loading: () => const Text(
                        'Yükleniyor...',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      error: (_, __) => const Text(
                        'Hata',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Arkadas Davet Et',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => InviteFriendModal(groupId: groupId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceHeader(ref, groupId, currentUserId),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Henüz işlem yok. İlk harcamayı ekleyin!'),
                  );
                }
                final membersAsync = ref.watch(groupMembersProvider(groupId));
                String getUsername(String userId) {
                  return membersAsync.maybeWhen(
                    data: (members) {
                      try {
                        final found = members.firstWhere(
                          (m) => m.userId == userId,
                        );
                        return found.username != null
                            ? '@${found.username}'
                            : userId.substring(0, 4);
                      } catch (_) {
                        return userId.substring(0, 4);
                      }
                    },
                    orElse: () => userId.substring(0, 4),
                  );
                }

                return ListView.builder(
                  reverse: false, // Akış en yeniden eskiye
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final isMe = tx.payerId == currentUserId;
                    final payerName = isMe ? 'Sen' : getUsername(tx.payerId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$payerName ödedi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isMe
                                        ? Colors.deepPurple
                                        : Colors.black87,
                                  ),
                                ),
                                Text(
                                  '₺${tx.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tx.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Divider(height: 24),
                            // Kime nasıl bölündüğü (Özet detay)
                            Wrap(
                              spacing: 8,
                              children: tx.splitData.entries.map((e) {
                                final owedIsMe = e.key == currentUserId;
                                final subName = owedIsMe
                                    ? 'Sen'
                                    : getUsername(e.key);
                                return Chip(
                                  label: Text('$subName: ₺${e.value}'),
                                  backgroundColor: owedIsMe
                                      ? Colors.red.shade50
                                      : Colors.grey.shade200,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Hata: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) =>
                AddExpenseSheet(groupId: groupId, currentUserId: currentUserId),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Harcama Ekle'),
      ),
    );
  }

  Widget _buildBalanceHeader(
    WidgetRef ref,
    String groupId,
    String currentUserId,
  ) {
    final balanceAsync = ref.watch(balanceEngineProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grup Bakiyesi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: balanceAsync.entries.map((e) {
                final userId = e.key;
                final balance = e.value;
                if (balance == 0) return const SizedBox.shrink();

                final isMe = userId == currentUserId;
                final isPositive = balance > 0;

                final String username = membersAsync.maybeWhen(
                  data: (members) {
                    try {
                      final found = members.firstWhere(
                        (m) => m.userId == userId,
                      );
                      return found.username != null
                          ? '@${found.username}'
                          : userId.substring(0, 4);
                    } catch (_) {
                      return userId.substring(0, 4);
                    }
                  },
                  orElse: () => userId.substring(0, 4),
                );

                final String displayName = isMe ? 'Sen' : username;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isPositive
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    '$displayName ${isPositive ? "Alacaklı:" : "Borçlu:"} ₺${balance.abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isPositive
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList()..removeWhere((e) => e is SizedBox),
            ),
          ),
        ],
      ),
    );
  }
}
