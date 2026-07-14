import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import '../filters/filters_provider.dart';
import '../groups/group_model.dart';
import '../groups/group_provider.dart';
import '../groups/group_transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> {
  final Set<String> _processingTransactions = <String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.invalidate(userGroupsProvider);

      try {
        final groups = await ref.read(userGroupsProvider.future);
        for (final group in groups) {
          if (group.id == null) continue;
          ref.invalidate(groupTransactionsStreamProvider(group.id!));
          ref.invalidate(groupMembersProvider(group.id!));
          ref.invalidate(balanceEngineProvider(group.id!));
        }
      } catch (_) {
        // Providers show their own error states.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(groupDataRefreshProvider);

    final groupsAsync = ref.watch(userGroupsProvider);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/dashboard');
              }
            },
          ),
          title: const Text('Borçlar'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.arrow_upward), text: 'Borçlarım'),
              Tab(icon: Icon(Icons.arrow_downward), text: 'Alacaklarım'),
              Tab(icon: Icon(Icons.fact_check_outlined), text: 'Onaylar'),
              Tab(icon: Icon(Icons.summarize_outlined), text: 'Özet'),
            ],
          ),
        ),
        body: groupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(friendlyErrorMessage(error))),
          data: (groups) {
            if (currentUserId == null) {
              return const Center(child: Text('Kullanıcı bilgisi alınamadı.'));
            }

            if (groups.isEmpty) {
              return const Center(
                child: Text('Henüz herhangi bir gruba dahil değilsiniz.'),
              );
            }

            return TabBarView(
              children: [
                _buildDebtList(
                  groups: groups,
                  currentUserId: currentUserId,
                  currency: currency,
                  exchanger: exchanger,
                  isOurDebt: true,
                ),
                _buildDebtList(
                  groups: groups,
                  currentUserId: currentUserId,
                  currency: currency,
                  exchanger: exchanger,
                  isOurDebt: false,
                ),
                _buildApprovals(
                  groups: groups,
                  currentUserId: currentUserId,
                  currency: currency,
                  exchanger: exchanger,
                ),
                _buildNetSummary(
                  groups: groups,
                  currentUserId: currentUserId,
                  currency: currency,
                  exchanger: exchanger,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebtList({
    required List<GroupModel> groups,
    required String currentUserId,
    required String currency,
    required ExchangeRateService exchanger,
    required bool isOurDebt,
  }) {
    final filters = ref.watch(transactionFilterProvider);
    final sections = <Widget>[];
    var total = 0.0;

    for (final group in groups) {
      final groupId = group.id;
      if (groupId == null) continue;
      if (filters.groupId.isNotEmpty && filters.groupId != groupId) continue;

      final members = ref.watch(groupMembersProvider(groupId));
      final transactions = ref.watch(groupTransactionsStreamProvider(groupId));

      final lines = transactions.maybeWhen(
        data: (items) => isOurDebt
            ? _collectOurDebts(
                transactions: items,
                group: group,
                currentUserId: currentUserId,
                members: members,
                filters: filters,
              )
            : _collectPeopleOweUs(
                transactions: items,
                group: group,
                currentUserId: currentUserId,
                members: members,
                filters: filters,
              ),
        orElse: () => const <_DebtLine>[],
      );

      if (lines.isEmpty) continue;

      final groupTotal = lines.fold<double>(
        0,
        (sum, line) => sum + line.amount,
      );
      total += groupTotal;

      final color = isOurDebt ? Colors.red.shade700 : Colors.green.shade700;

      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '$currency${exchanger.convertFromTRY(groupTotal, currency).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtRow(
                      title: line.title,
                      subtitle: isOurDebt
                          ? 'Borçlu olunan kişi: ${line.counterpartyName}'
                          : 'Bize borçlu: ${line.counterpartyName}',
                      amountText:
                          '$currency${exchanger.convertFromTRY(line.amount, currency).toStringAsFixed(2)}',
                      date: line.date,
                      accentColor: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final color = isOurDebt ? Colors.red : Colors.green;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilterCard(groups),
        const SizedBox(height: 12),
        if (sections.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 56),
            child: Center(
              child: Text(
                isOurDebt
                    ? 'Aktif borcunuz bulunmuyor.'
                    : 'Size olan aktif borç bulunmuyor.',
              ),
            ),
          )
        else ...[
          _SummaryCard(
            label: isOurDebt ? 'Toplam Borç' : 'Toplam Alacak',
            value:
                '$currency${exchanger.convertFromTRY(total, currency).toStringAsFixed(2)}',
            accentColor: color,
          ),
          const SizedBox(height: 12),
          ...sections,
        ],
      ],
    );
  }

  Widget _buildApprovals({
    required List<GroupModel> groups,
    required String currentUserId,
    required String currency,
    required ExchangeRateService exchanger,
  }) {
    final awaitingMe = <_PendingLine>[];
    final awaitingOthers = <_PendingLine>[];

    for (final group in groups) {
      final groupId = group.id;
      if (groupId == null) continue;

      final members = ref.watch(groupMembersProvider(groupId));
      final transactions = ref.watch(groupTransactionsStreamProvider(groupId));

      transactions.whenData((items) {
        for (final transaction in items) {
          transaction.splitData.forEach((participantId, rawValue) {
            if (participantId == transaction.payerId) return;

            final status = participantApprovalStatus(
              transaction.splitData,
              participantId,
              transaction.payerId,
            );

            if (status != DebtApprovalStatus.pending) return;

            final amount = _amountFromSplit(rawValue);
            if (amount <= 0) return;

            final line = _PendingLine(
              transactionId: transaction.id,
              groupId: groupId,
              groupName: group.name,
              title: transaction.description,
              counterpartyName: _memberName(
                members,
                participantId == currentUserId
                    ? transaction.payerId
                    : participantId,
                currentUserId,
              ),
              amount: amount,
            );

            if (participantId == currentUserId) {
              awaitingMe.add(line);
            } else if (transaction.payerId == currentUserId) {
              awaitingOthers.add(line);
            }
          });
        }
      });
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Onayınızı Bekleyenler',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (awaitingMe.isEmpty)
          const Text(
            'Onayınızı bekleyen borç bulunmuyor.',
            style: TextStyle(color: Colors.black54),
          )
        else
          ...awaitingMe.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text(
                  '${item.groupName} • ${item.counterpartyName}\n'
                  '${item.amount.toStringAsFixed(2)} TL',
                ),
                isThreeLine: true,
                trailing: _processingTransactions.contains(item.transactionId)
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Reddet',
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.red.shade700,
                            onPressed: () => _rejectDebt(item),
                          ),
                          IconButton(
                            tooltip: 'Onayla',
                            icon: const Icon(Icons.check_rounded),
                            color: Colors.green.shade700,
                            onPressed: () => _acknowledgeDebt(item),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        const SizedBox(height: 28),
        const Text(
          'Karşı Tarafın Onayını Bekleyenler',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (awaitingOthers.isEmpty)
          const Text(
            'Karşı tarafın onayını bekleyen borç bulunmuyor.',
            style: TextStyle(color: Colors.black54),
          )
        else
          ...awaitingOthers.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(item.title),
                subtitle: Text('${item.groupName} • ${item.counterpartyName}'),
                trailing: Text(
                  '$currency${exchanger.convertFromTRY(item.amount, currency).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNetSummary({
    required List<GroupModel> groups,
    required String currentUserId,
    required String currency,
    required ExchangeRateService exchanger,
  }) {
    final filters = ref.watch(transactionFilterProvider);
    final sections = <Widget>[];

    for (final group in groups) {
      final groupId = group.id;
      if (groupId == null) continue;
      if (filters.groupId.isNotEmpty && filters.groupId != groupId) continue;

      final members = ref.watch(groupMembersProvider(groupId));
      final balances = ref.watch(balanceEngineProvider(groupId));

      final settlements = members.maybeWhen(
        data: (items) => _buildSettlements(balances, items, currentUserId),
        orElse: () => const <_SettlementLine>[],
      );

      if (settlements.isEmpty) continue;

      final total = settlements.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );

      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toplam: $currency${exchanger.convertFromTRY(total, currency).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...settlements.map(
                  (item) => _DebtRow(
                    title: '${item.fromName} → ${item.toName}',
                    subtitle: 'Netleştirilmiş borç',
                    amountText:
                        '$currency${exchanger.convertFromTRY(item.amount, currency).toStringAsFixed(2)}',
                    accentColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilterCard(groups),
        const SizedBox(height: 12),
        if (sections.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 56),
            child: Center(child: Text('Netleştirilecek borç bulunmuyor.')),
          )
        else
          ...sections,
      ],
    );
  }

  Widget _buildFilterCard(List<GroupModel> groups) {
    final filters = ref.watch(transactionFilterProvider);
    var groupId = filters.groupId;
    DateTime? start = filters.start;
    DateTime? end = filters.end;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              children: [
                DropdownButtonFormField<String>(
                  value: groupId,
                  decoration: const InputDecoration(
                    labelText: 'Grup',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Tümü')),
                    ...groups
                        .where((group) => group.id != null)
                        .map(
                          (group) => DropdownMenuItem(
                            value: group.id!,
                            child: Text(group.name),
                          ),
                        ),
                  ],
                  onChanged: (value) {
                    setLocalState(() => groupId = value ?? '');
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
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
                              start = range.start;
                              end = range.end;
                            });
                          }
                        },
                        child: Text(
                          start == null || end == null
                              ? 'Tarih seç'
                              : '${start!.day}.${start!.month}.${start!.year} - '
                                    '${end!.day}.${end!.month}.${end!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Filtreleri temizle',
                      icon: const Icon(Icons.filter_alt_off),
                      onPressed: () {
                        setLocalState(() {
                          groupId = '';
                          start = null;
                          end = null;
                        });
                        ref.read(transactionFilterProvider.notifier).clear();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filtrele'),
                    onPressed: () {
                      final notifier = ref.read(
                        transactionFilterProvider.notifier,
                      );
                      notifier.clear();
                      notifier.setGroup(groupId);
                      notifier.setDateRange(start, end);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _acknowledgeDebt(_PendingLine item) async {
    await _runPendingAction(
      item,
      () => ref
          .read(groupServiceProvider)
          .acknowledgeDebtParticipant(item.transactionId!),
    );
  }

  Future<void> _rejectDebt(_PendingLine item) async {
    await _runPendingAction(
      item,
      () => ref
          .read(groupServiceProvider)
          .rejectDebtParticipant(item.transactionId!),
    );
  }

  Future<void> _runPendingAction(
    _PendingLine item,
    Future<void> Function() action,
  ) async {
    final transactionId = item.transactionId;
    if (transactionId == null ||
        _processingTransactions.contains(transactionId)) {
      return;
    }

    setState(() => _processingTransactions.add(transactionId));

    try {
      await action();
      ref.invalidate(groupTransactionsStreamProvider(item.groupId));
      ref.invalidate(balanceEngineProvider(item.groupId));
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
        setState(() => _processingTransactions.remove(transactionId));
      }
    }
  }

  List<_DebtLine> _collectOurDebts({
    required List<GroupTransactionModel> transactions,
    required GroupModel group,
    required String currentUserId,
    required AsyncValue<List<GroupMemberModel>> members,
    required TransactionFilters filters,
  }) {
    final results = <_DebtLine>[];

    for (final transaction in transactions) {
      if (transaction.payerId == currentUserId) continue;
      if (!_matchesDate(transaction.createdAt, filters)) continue;

      final rawValue = transaction.splitData[currentUserId];
      if (rawValue == null) continue;

      final status = participantApprovalStatus(
        transaction.splitData,
        currentUserId,
        transaction.payerId,
      );

      // Only approved and payment_pending are live financial debts.
      if (!isDebtCountedStatus(status)) continue;

      final amount = _amountFromSplit(rawValue);
      if (amount <= 0) continue;

      results.add(
        _DebtLine(
          title: transaction.description,
          counterpartyName: _memberName(
            members,
            transaction.payerId,
            currentUserId,
          ),
          amount: amount,
          date: transaction.createdAt,
          groupName: group.name,
        ),
      );
    }

    return results;
  }

  List<_DebtLine> _collectPeopleOweUs({
    required List<GroupTransactionModel> transactions,
    required GroupModel group,
    required String currentUserId,
    required AsyncValue<List<GroupMemberModel>> members,
    required TransactionFilters filters,
  }) {
    final results = <_DebtLine>[];

    for (final transaction in transactions) {
      if (transaction.payerId != currentUserId) continue;
      if (!_matchesDate(transaction.createdAt, filters)) continue;

      transaction.splitData.forEach((participantId, rawValue) {
        if (participantId == transaction.payerId) return;

        final status = participantApprovalStatus(
          transaction.splitData,
          participantId,
          transaction.payerId,
        );

        // settled, pending, and rejected shares are intentionally excluded.
        if (!isDebtCountedStatus(status)) return;

        final amount = _amountFromSplit(rawValue);
        if (amount <= 0) return;

        results.add(
          _DebtLine(
            title: transaction.description,
            counterpartyName: _memberName(
              members,
              participantId,
              currentUserId,
            ),
            amount: amount,
            date: transaction.createdAt,
            groupName: group.name,
          ),
        );
      });
    }

    return results;
  }

  bool _matchesDate(DateTime? date, TransactionFilters filters) {
    if (filters.start == null || filters.end == null || date == null) {
      return true;
    }

    final normalized = DateTime(date.year, date.month, date.day);
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

    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  List<_SettlementLine> _buildSettlements(
    Map<String, double> balances,
    List<GroupMemberModel> members,
    String currentUserId,
  ) {
    final creditors =
        balances.entries
            .where((entry) => entry.value > 0.0001)
            .map(
              (entry) => _BalanceNode(
                userId: entry.key,
                amount: entry.value,
                name: _displayName(members, entry.key, currentUserId),
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final debtors =
        balances.entries
            .where((entry) => entry.value < -0.0001)
            .map(
              (entry) => _BalanceNode(
                userId: entry.key,
                amount: entry.value.abs(),
                name: _displayName(members, entry.key, currentUserId),
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final results = <_SettlementLine>[];
    var creditorIndex = 0;
    var debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final amount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      results.add(
        _SettlementLine(
          fromName: debtor.name,
          toName: creditor.name,
          amount: amount,
        ),
      );

      creditor.amount -= amount;
      debtor.amount -= amount;

      if (creditor.amount <= 0.0001) creditorIndex++;
      if (debtor.amount <= 0.0001) debtorIndex++;
    }

    return results;
  }

  double _amountFromSplit(dynamic value) {
    if (value is Map) {
      return (value['amount'] as num?)?.toDouble() ?? 0;
    }

    return (value as num?)?.toDouble() ?? 0;
  }

  String _memberName(
    AsyncValue<List<GroupMemberModel>> members,
    String userId,
    String currentUserId,
  ) {
    if (userId == currentUserId) return 'Sen';

    return members.maybeWhen(
      data: (items) => _displayName(items, userId, currentUserId),
      orElse: () => 'Kullanıcı',
    );
  }

  String _displayName(
    List<GroupMemberModel> members,
    String userId,
    String currentUserId,
  ) {
    if (userId == currentUserId) return 'Sen';

    try {
      final member = members.firstWhere((item) => item.userId == userId);
      final username = member.username?.trim();

      return username == null || username.isEmpty ? 'Kullanıcı' : '@$username';
    } catch (_) {
      return 'Kullanıcı';
    }
  }
}

class _DebtRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amountText;
  final DateTime? date;
  final Color accentColor;

  const _DebtRow({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.accentColor,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (date != null) ...[
                const SizedBox(height: 2),
                Text(
                  '${date!.day.toString().padLeft(2, '0')}.'
                  '${date!.month.toString().padLeft(2, '0')}.${date!.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amountText,
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: accentColor.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtLine {
  final String title;
  final String counterpartyName;
  final double amount;
  final DateTime? date;
  final String groupName;

  const _DebtLine({
    required this.title,
    required this.counterpartyName,
    required this.amount,
    required this.date,
    required this.groupName,
  });
}

class _PendingLine {
  final String? transactionId;
  final String groupId;
  final String groupName;
  final String title;
  final String counterpartyName;
  final double amount;

  const _PendingLine({
    required this.transactionId,
    required this.groupId,
    required this.groupName,
    required this.title,
    required this.counterpartyName,
    required this.amount,
  });
}

class _SettlementLine {
  final String fromName;
  final String toName;
  final double amount;

  const _SettlementLine({
    required this.fromName,
    required this.toName,
    required this.amount,
  });
}

class _BalanceNode {
  final String userId;
  final String name;
  double amount;

  _BalanceNode({
    required this.userId,
    required this.name,
    required this.amount,
  });
}
