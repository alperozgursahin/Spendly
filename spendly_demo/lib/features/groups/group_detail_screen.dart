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
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import '../filters/filters_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // The realtime .stream() providers occasionally come back empty on
    // their very first subscribe (a timing race right after navigation),
    // and only self-correct once something else forces a fresh subscribe
    // (e.g. adding a new expense invalidates them). Force that fresh
    // subscribe proactively every time this screen opens instead of
    // waiting on that coincidence.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(groupTransactionsStreamProvider(widget.groupId));
      ref.invalidate(groupMembersProvider(widget.groupId));
      ref.invalidate(balanceEngineProvider(widget.groupId));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(groupDataRefreshProvider);
    final paidOverrides = ref.watch(groupPaidOverridesProvider);
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);
    final transactionsAsync = ref.watch(
      groupTransactionsStreamProvider(widget.groupId),
    );
    final currentUserId = ref.watch(authClientProvider).currentUser?.id ?? '';
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            context.push(
              '/groups/${widget.groupId}/info',
              extra: widget.groupName,
            );
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
                      widget.groupName,
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
                builder: (_) => InviteFriendModal(groupId: widget.groupId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBalanceHeader(ref, widget.groupId, currentUserId),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Henüz işlem yok. İlk harcamayı ekleyin!'),
                  );
                }
                final membersListAsync = ref.watch(
                  groupMembersProvider(widget.groupId),
                );

                String getUsername(String userId) {
                  return membersListAsync.maybeWhen(
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

                final filters = ref.watch(transactionFilterProvider);

                final filtered = transactions.where((tx) {
                  if (filters.start != null && filters.end != null) {
                    if (tx.createdAt != null && (tx.createdAt!.isBefore(filters.start!) || tx.createdAt!.isAfter(filters.end!))) {
                      return false;
                    }
                  }
                  if (filters.personId.isNotEmpty && tx.payerId != filters.personId) {
                    return false;
                  }
                  return true;
                }).toList();

                return Column(
                  children: [
                    _buildGroupFilterCard(context, ref, membersAsync, currentUserId),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final tx = filtered[index];
                    final isMe = tx.payerId == currentUserId;
                    final payerName = isMe ? 'Sen' : getUsername(tx.payerId);
                    final isActive = _activeTransactionId == tx.id;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _activeTransactionId = isActive ? null : tx.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isActive
                                ? Colors.deepPurple.shade200
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$payerName ödedi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMe
                                          ? Colors.green.shade700
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '$currency${exchanger.convertFromTRY(tx.amount, currency).toStringAsFixed(2)}',
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: tx.splitData.entries.map((e) {
                                  final participantId = e.key;
                                  final splitValue = e.value;
                                  final isCurrentUser =
                                      participantId == currentUserId;
                                  final isPayer = participantId == tx.payerId;

                                  final amount = splitValue is Map
                                      ? (splitValue['amount'] as num?)
                                                ?.toDouble() ??
                                            0.0
                                      : (splitValue as num).toDouble();

                                  final subName = isCurrentUser
                                      ? 'Sen'
                                      : getUsername(participantId);
                                  final amountLabel =
                                      '$subName: $currency${exchanger.convertFromTRY(amount, currency).toStringAsFixed(2)}';

                                  final status = participantApprovalStatus(
                                    tx.splitData,
                                    participantId,
                                    tx.payerId,
                                  );

                                  Future<void> setApprovalStatus(
                                    String newStatus,
                                  ) async {
                                    if (tx.id == null) return;

                                    final existingValue =
                                        tx.splitData[participantId];
                                    final existingPaid = existingValue is Map
                                        ? (existingValue['paid'] as bool?) ??
                                              false
                                        : isPayer;

                                    try {
                                      await ref
                                          .read(groupServiceProvider)
                                          .updateOwnSplitEntry(
                                            transactionId: tx.id!,
                                            paid: existingPaid,
                                            status: newStatus,
                                          );

                                      ref.invalidate(
                                        groupTransactionsStreamProvider(
                                          widget.groupId,
                                        ),
                                      );
                                      ref.invalidate(
                                        balanceEngineProvider(widget.groupId),
                                      );
                                      ref.read(groupDataRefreshProvider.notifier).state++;
                                    } catch (_) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'İşlem gerçekleştirilemedi. Tekrar deneyin.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }

                                  if (status == DebtApprovalStatus.pending) {
                                    final canRespond =
                                        isCurrentUser && isActive;
                                    return _buildPendingChip(
                                      amountLabel,
                                      canRespond,
                                      () => setApprovalStatus('approved'),
                                      () => setApprovalStatus('rejected'),
                                    );
                                  }

                                  if (status == DebtApprovalStatus.rejected) {
                                    return _buildRejectedChip(amountLabel);
                                  }

                                  final basePaid = splitValue is Map
                                      ? (splitValue['paid'] as bool?) ?? false
                                      : isPayer;
                                  final paid =
                                      _isParticipantPaid(
                                      tx,
                                      participantId,
                                      paidOverrides,
                                      ) ||
                                      basePaid;

                                  final chipColor = paid
                                      ? Colors.green.shade50
                                      : Colors.red.shade50;
                                  final borderColor = paid
                                      ? Colors.green.shade200
                                      : Colors.red.shade200;
                                  final textColor = paid
                                      ? Colors.green.shade700
                                      : Colors.red.shade700;
                                  final showActionButton =
                                      isCurrentUser && isActive;

                                  Future<void> togglePaidState() async {
                                    if (tx.id == null) return;

                                    final transactionId = tx.id!;
                                    final currentPaid = paid;

                                    ref
                                        .read(
                                          groupPaidOverridesProvider.notifier,
                                        )
                                        .setPaid(
                                          transactionId,
                                          participantId,
                                          !currentPaid,
                                        );

                                    final existingValue =
                                        tx.splitData[participantId];
                                    final existingPaid = existingValue is Map
                                        ? (existingValue['paid'] as bool?) ??
                                              false
                                        : isPayer;

                                    try {
                                      await ref
                                          .read(groupServiceProvider)
                                          .updateOwnSplitEntry(
                                            transactionId: transactionId,
                                            paid: !existingPaid,
                                            status: 'approved',
                                          );

                                      ref.invalidate(
                                        groupTransactionsStreamProvider(
                                          widget.groupId,
                                        ),
                                      );
                                      ref.invalidate(
                                        balanceEngineProvider(widget.groupId),
                                      );
                                      ref.read(groupDataRefreshProvider.notifier).state++;
                                    } catch (_) {
                                      ref
                                          .read(
                                            groupPaidOverridesProvider.notifier,
                                          )
                                          .setPaid(
                                            transactionId,
                                            participantId,
                                            currentPaid,
                                          );
                                    }
                                  }

                                  final chipBody = AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: chipColor,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                            child: Text(
                                            amountLabel,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (showActionButton) ...[
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(
                                              color: paid
                                                  ? Colors.green.shade600
                                                  : Colors.red.shade600,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      (paid
                                                              ? Colors.green
                                                              : Colors.red)
                                                          .withValues(
                                                            alpha: 0.22,
                                                          ),
                                                  blurRadius: 7,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              paid
                                                  ? Icons.close_rounded
                                                  : Icons.check_rounded,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );

                                  if (!showActionButton) {
                                    return chipBody;
                                  }

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: togglePaidState,
                                      borderRadius: BorderRadius.circular(18),
                                      child: chipBody,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
            builder: (_) => AddExpenseSheet(
              groupId: widget.groupId,
              currentUserId: currentUserId,
            ),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('Harcama Ekle'),
      ),
    );
  }

  Widget _buildPendingChip(
    String amountLabel,
    bool canRespond,
    VoidCallback onApprove,
    VoidCallback onReject,
  ) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_top, size: 16, color: Colors.amber.shade800),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$amountLabel · Onay bekliyor',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canRespond) ...[
            const SizedBox(width: 10),
            InkWell(
              onTap: onApprove,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: onReject,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (!canRespond) return chip;
    return Material(color: Colors.transparent, child: chip);
  }

  Widget _buildRejectedChip(String amountLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$amountLabel · Reddedildi',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isParticipantPaid(
    GroupTransactionModel tx,
    String participantId,
    Map<String, Map<String, bool>> overrides,
  ) {
    final transactionId = tx.id;
    if (transactionId != null) {
      final override = overrides[transactionId]?[participantId];
      if (override != null) return override;
    }

    final rawValue = tx.splitData[participantId];
    if (rawValue is Map) {
      return (rawValue['paid'] as bool?) ?? (participantId == tx.payerId);
    }

    return participantId == tx.payerId;
  }

  Widget _buildGroupFilterCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<GroupMemberModel>> membersAsync,
    String currentUserId,
  ) {
    final filters = ref.watch(transactionFilterProvider);
    var selectedPersonId = filters.personId;
    DateTime? selectedStart = filters.start;
    DateTime? selectedEnd = filters.end;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            final people = membersAsync.maybeWhen(
              data: (members) => members.map((m) => m.userId).toSet().toList()..sort(),
              orElse: () => <String>[],
            );

            if (selectedPersonId.isNotEmpty && !people.contains(selectedPersonId)) {
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
                        decoration: const InputDecoration(labelText: 'Kişi', isDense: true),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Hepsi')),
                          ...membersAsync.maybeWhen(
                            data: (members) => members.map((m) {
                              final label = m.userId == currentUserId
                                  ? 'Sen'
                                  : (m.username != null ? '@${m.username}' : m.userId.substring(0, 4));
                              return DropdownMenuItem(value: m.userId, child: Text(label));
                            }).toList(),
                            orElse: () => const <DropdownMenuItem<String>>[],
                          ),
                        ],
                        onChanged: (value) => setLocalState(() => selectedPersonId = value ?? ''),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final r = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (r != null) {
                            setLocalState(() {
                              selectedStart = r.start;
                              selectedEnd = r.end;
                            });
                          }
                        },
                        child: Text(
                          selectedStart != null && selectedEnd != null
                              ? '${selectedStart!.day}.${selectedStart!.month}.${selectedStart!.year} - ${selectedEnd!.day}.${selectedEnd!.month}.${selectedEnd!.year}'
                              : 'Tarih seç',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final notifier = ref.read(transactionFilterProvider.notifier);
                      notifier.setPerson(selectedPersonId);
                      notifier.setDateRange(selectedStart, selectedEnd);
                      notifier.setGroup('');
                      notifier.setCategory('');
                    },
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filtrele'),
                  ),
                ),
              ],
            );
          },
        ),
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
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);

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
                      '$displayName ${isPositive ? "Alacaklı:" : "Borçlu:"} $currency${exchanger.convertFromTRY(balance.abs(), currency).toStringAsFixed(2)}',
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
