import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../filters/filters_provider.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import 'add_expense_sheet.dart';
import 'group_info_screen.dart';
import 'group_model.dart';
import 'group_provider.dart';
import 'group_transaction_model.dart';
import 'invite_friend_modal.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  String? _activeTransactionId;
  final Set<String> _processingActions = <String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(groupTransactionsStreamProvider(widget.groupId));
      ref.invalidate(groupMembersProvider(widget.groupId));
      ref.invalidate(balanceEngineProvider(widget.groupId));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(groupDataRefreshProvider);

    final currentUserId = ref.watch(authClientProvider).currentUser?.id ?? '';
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);
    final members = ref.watch(groupMembersProvider(widget.groupId));
    final transactions = ref.watch(
      groupTransactionsStreamProvider(widget.groupId),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.push(
              '/groups/${widget.groupId}/info',
              extra: widget.groupName,
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.deepPurple.shade100,
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
                      widget.groupName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    members.when(
                      data: (items) => Text(
                        '${items.length} katılımcı',
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
                        'Katılımcılar yüklenemedi',
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
            tooltip: 'Arkadaş davet et',
            icon: const Icon(Icons.person_add),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => InviteFriendModal(groupId: widget.groupId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceHeader(
            currentUserId: currentUserId,
            currency: currency,
            exchanger: exchanger,
          ),
          _buildFilterCard(currentUserId),
          Expanded(
            child: transactions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Hata: $error')),
              data: (items) {
                final filtered = _filteredTransactions(items);

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Henüz işlem yok. İlk harcamayı ekleyin.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final transaction = filtered[index];

                    return _buildTransactionCard(
                      transaction: transaction,
                      currentUserId: currentUserId,
                      currency: currency,
                      exchanger: exchanger,
                      members: members,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.receipt_long),
        label: const Text('Harcama Ekle'),
        onPressed: currentUserId.isEmpty
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AddExpenseSheet(
                    groupId: widget.groupId,
                    currentUserId: currentUserId,
                  ),
                );
              },
      ),
    );
  }

  Widget _buildTransactionCard({
    required GroupTransactionModel transaction,
    required String currentUserId,
    required String currency,
    required ExchangeRateService exchanger,
    required AsyncValue<List<GroupMemberModel>> members,
  }) {
    final transactionId = transaction.id ?? '';
    final isExpanded = _activeTransactionId == transactionId;
    final payerName = transaction.payerId == currentUserId
        ? 'Sen'
        : _memberName(members, transaction.payerId, currentUserId);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() {
          _activeTransactionId = isExpanded ? null : transactionId;
        });
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isExpanded ? Colors.deepPurple.shade200 : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$payerName ödedi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: transaction.payerId == currentUserId
                            ? Colors.green.shade700
                            : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '$currency${exchanger.convertFromTRY(transaction.amount, currency).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(transaction.description),
              if (transaction.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(transaction.createdAt!),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: transaction.splitData.entries.map((entry) {
                  return _buildParticipantChip(
                    transaction: transaction,
                    participantId: entry.key,
                    rawValue: entry.value,
                    currentUserId: currentUserId,
                    currency: currency,
                    exchanger: exchanger,
                    members: members,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParticipantChip({
    required GroupTransactionModel transaction,
    required String participantId,
    required dynamic rawValue,
    required String currentUserId,
    required String currency,
    required ExchangeRateService exchanger,
    required AsyncValue<List<GroupMemberModel>> members,
  }) {
    final isPayer = participantId == transaction.payerId;
    final isCurrentUser = participantId == currentUserId;
    final amount = _splitAmount(rawValue);
    final participantName = isCurrentUser
        ? 'Sen'
        : _memberName(members, participantId, currentUserId);

    final amountLabel =
        '$participantName: $currency${exchanger.convertFromTRY(amount, currency).toStringAsFixed(2)}';

    if (isPayer) {
      return _statusChip(
        amountLabel: amountLabel,
        label: 'Ödeyen',
        icon: Icons.account_balance_wallet_rounded,
        backgroundColor: Colors.deepPurple.shade50,
        borderColor: Colors.deepPurple.shade200,
        textColor: Colors.deepPurple.shade800,
      );
    }

    final status = participantApprovalStatus(
      transaction.splitData,
      participantId,
      transaction.payerId,
    );

    final transactionId = transaction.id;
    final actionKey = '$transactionId:$participantId';
    final isBusy = _processingActions.contains(actionKey);

    String? actionLabel;
    IconData? actionIcon;
    VoidCallback? onActionPressed;

    if (transactionId != null && !isBusy) {
      if (status == DebtApprovalStatus.pending && isCurrentUser) {
        actionLabel = 'Acknowledge';
        actionIcon = Icons.check_rounded;
        onActionPressed = () => _runLifecycleAction(
          transactionId: transactionId,
          participantId: participantId,
          status: status,
        );
      } else if (status == DebtApprovalStatus.approved && isCurrentUser) {
        actionLabel = 'Mark as Paid';
        actionIcon = Icons.payments_rounded;
        onActionPressed = () => _runLifecycleAction(
          transactionId: transactionId,
          participantId: participantId,
          status: status,
        );
      } else if (status == DebtApprovalStatus.paymentPending &&
          transaction.payerId == currentUserId) {
        actionLabel = 'Confirm Receipt';
        actionIcon = Icons.done_all_rounded;
        onActionPressed = () => _runLifecycleAction(
          transactionId: transactionId,
          participantId: participantId,
          status: status,
        );
      }
    }

    switch (status) {
      case DebtApprovalStatus.pending:
        return _statusChip(
          amountLabel: amountLabel,
          label: 'Onay bekliyor',
          icon: Icons.hourglass_top_rounded,
          backgroundColor: Colors.amber.shade50,
          borderColor: Colors.amber.shade300,
          textColor: Colors.amber.shade900,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onActionPressed: onActionPressed,
          isBusy: isBusy,
        );

      case DebtApprovalStatus.approved:
        return _statusChip(
          amountLabel: amountLabel,
          label: isCurrentUser ? 'Onaylandı' : 'Aktif borç',
          icon: Icons.verified_rounded,
          backgroundColor: Colors.blue.shade50,
          borderColor: Colors.blue.shade200,
          textColor: Colors.blue.shade900,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onActionPressed: onActionPressed,
          isBusy: isBusy,
        );

      case DebtApprovalStatus.paymentPending:
        return _statusChip(
          amountLabel: amountLabel,
          label: transaction.payerId == currentUserId
              ? 'Ödeme onayı bekleniyor'
              : 'Ödeme bildirildi',
          icon: Icons.schedule_send_rounded,
          backgroundColor: Colors.orange.shade50,
          borderColor: Colors.orange.shade200,
          textColor: Colors.orange.shade900,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onActionPressed: onActionPressed,
          isBusy: isBusy,
        );

      case DebtApprovalStatus.settled:
        return _statusChip(
          amountLabel: amountLabel,
          label: 'Settled',
          icon: Icons.verified_rounded,
          backgroundColor: Colors.green.shade50,
          borderColor: Colors.green.shade300,
          textColor: Colors.green.shade800,
        );

      case DebtApprovalStatus.rejected:
        return _statusChip(
          amountLabel: amountLabel,
          label: 'Reddedildi',
          icon: Icons.block_rounded,
          backgroundColor: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          textColor: Colors.grey.shade700,
        );
    }
  }

  Widget _statusChip({
    required String amountLabel,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    String? actionLabel,
    IconData? actionIcon,
    VoidCallback? onActionPressed,
    bool isBusy = false,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 370),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          Icon(icon, size: 16, color: textColor),
          Text(
            '$amountLabel · $label',
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
          ),
          if (isBusy)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            )
          else if (actionLabel != null && onActionPressed != null)
            TextButton.icon(
              onPressed: onActionPressed,
              icon: Icon(actionIcon ?? Icons.check_rounded, size: 16),
              label: Text(actionLabel),
              style: TextButton.styleFrom(
                foregroundColor: textColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _runLifecycleAction({
    required String transactionId,
    required String participantId,
    required DebtApprovalStatus status,
  }) async {
    final actionKey = '$transactionId:$participantId';

    if (_processingActions.contains(actionKey)) return;

    setState(() => _processingActions.add(actionKey));

    try {
      final service = ref.read(groupServiceProvider);

      switch (status) {
        case DebtApprovalStatus.pending:
          await service.acknowledgeDebtParticipant(transactionId);

        case DebtApprovalStatus.approved:
          await service.markPaymentSent(transactionId);

        case DebtApprovalStatus.paymentPending:
          await service.confirmPaymentReceived(
            transactionId: transactionId,
            participantId: participantId,
          );

        case DebtApprovalStatus.settled:
        case DebtApprovalStatus.rejected:
          return;
      }

      ref.invalidate(groupTransactionsStreamProvider(widget.groupId));
      ref.invalidate(balanceEngineProvider(widget.groupId));
      ref.read(groupDataRefreshProvider.notifier).state++;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İşlem gerçekleştirilemedi. Lütfen tekrar deneyin.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingActions.remove(actionKey));
      }
    }
  }

  Widget _buildBalanceHeader({
    required String currentUserId,
    required String currency,
    required ExchangeRateService exchanger,
  }) {
    final balances = ref.watch(balanceEngineProvider(widget.groupId));
    final members = ref.watch(groupMembersProvider(widget.groupId));

    final entries =
        balances.entries.where((entry) => entry.value.abs() > 0.0001).toList()
          ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grup Bakiyesi',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Text(
              'Aktif borç bulunmuyor.',
              style: TextStyle(color: Colors.black54),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entries.map((entry) {
                  final isPositive = entry.value > 0;
                  final displayName = entry.key == currentUserId
                      ? 'Sen'
                      : _memberName(members, entry.key, currentUserId);

                  final background = isPositive
                      ? Colors.green.shade50
                      : Colors.red.shade50;
                  final border = isPositive
                      ? Colors.green.shade200
                      : Colors.red.shade200;
                  final text = isPositive
                      ? Colors.green.shade700
                      : Colors.red.shade700;

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      '$displayName ${isPositive ? "Alacaklı" : "Borçlu"}: '
                      '$currency${exchanger.convertFromTRY(entry.value.abs(), currency).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(String currentUserId) {
    final filters = ref.watch(transactionFilterProvider);
    var selectedPersonId = filters.personId;
    DateTime? selectedStart = filters.start;
    DateTime? selectedEnd = filters.end;

    final members = ref.watch(groupMembersProvider(widget.groupId));

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            final memberList = members.maybeWhen(
              data: (items) => items,
              orElse: () => const <GroupMemberModel>[],
            );

            if (selectedPersonId.isNotEmpty &&
                !memberList.any(
                  (member) => member.userId == selectedPersonId,
                )) {
              selectedPersonId = '';
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPersonId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Ödeyen kişi',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tümü'),
                          ),
                          ...memberList.map(
                            (member) => DropdownMenuItem(
                              value: member.userId,
                              child: Text(
                                member.userId == currentUserId
                                    ? 'Sen'
                                    : (member.username == null ||
                                              member.username!.isEmpty
                                          ? 'Kullanıcı'
                                          : '@${member.username}'),
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setLocalState(() => selectedPersonId = value ?? '');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 3650),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );

                        if (range != null) {
                          setLocalState(() {
                            selectedStart = range.start;
                            selectedEnd = range.end;
                          });
                        }
                      },
                      child: Text(
                        selectedStart == null || selectedEnd == null
                            ? 'Tarih'
                            : '${selectedStart!.day}.${selectedStart!.month} '
                                  '- ${selectedEnd!.day}.${selectedEnd!.month}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {
                          setLocalState(() {
                            selectedPersonId = '';
                            selectedStart = null;
                            selectedEnd = null;
                          });
                          ref.read(transactionFilterProvider.notifier).clear();
                        },
                        child: const Text('Sıfırla'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Filtrele'),
                        onPressed: () {
                          final notifier = ref.read(
                            transactionFilterProvider.notifier,
                          );
                          notifier.setPerson(selectedPersonId);
                          notifier.setDateRange(selectedStart, selectedEnd);
                          notifier.setGroup('');
                          notifier.setCategory('');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<GroupTransactionModel> _filteredTransactions(
    List<GroupTransactionModel> transactions,
  ) {
    final filters = ref.read(transactionFilterProvider);

    return transactions.where((transaction) {
      if (filters.personId.isNotEmpty &&
          transaction.payerId != filters.personId) {
        return false;
      }

      final date = transaction.createdAt;
      if (filters.start != null && filters.end != null && date != null) {
        final transactionDate = DateTime(date.year, date.month, date.day);
        final start = DateTime(
          filters.start!.year,
          filters.start!.month,
          filters.start!.day,
        );
        final end = DateTime(
          filters.end!.year,
          filters.end!.month,
          filters.end!.day,
        );

        if (transactionDate.isBefore(start) || transactionDate.isAfter(end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  String _memberName(
    AsyncValue<List<GroupMemberModel>> members,
    String userId,
    String currentUserId,
  ) {
    if (userId == currentUserId) return 'Sen';

    return members.maybeWhen(
      data: (items) {
        try {
          final member = items.firstWhere((item) => item.userId == userId);
          final username = member.username?.trim();

          return username == null || username.isEmpty
              ? 'Kullanıcı'
              : '@$username';
        } catch (_) {
          return 'Kullanıcı';
        }
      },
      orElse: () => 'Kullanıcı',
    );
  }

  double _splitAmount(dynamic rawValue) {
    if (rawValue is Map) {
      return (rawValue['amount'] as num?)?.toDouble() ?? 0;
    }

    return (rawValue as num?)?.toDouble() ?? 0;
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();

    return '${local.day.toString().padLeft(2, '0')}.'
        '${local.month.toString().padLeft(2, '0')}.'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
