import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../groups/group_model.dart';
import '../groups/group_provider.dart';
import '../groups/group_transaction_model.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import '../filters/filters_provider.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(groupDataRefreshProvider);
    final groupsAsync = ref.watch(userGroupsProvider);
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);
    final currentUserId = ref.watch(authClientProvider).currentUser?.id;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Geri',
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
                return;
              }
              context.go('/dashboard');
            },
          ),
          title: const Text('Borçlar'),
          bottom: const TabBar(
            isScrollable: false,
            labelPadding: EdgeInsets.zero,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(child: Center(child: Text('Bizim Borçlarımız'))),
              Tab(child: Center(child: Text('Bize Borçlular'))),
              Tab(child: Center(child: Text('Net Özet'))),
            ],
          ),
        ),
        body: groupsAsync.when(
          data: (groups) {
            if (currentUserId == null) {
              return const Center(child: Text('Kullanıcı bilgisi alınamadı.'));
            }

            if (groups.isEmpty) {
              return const Center(child: Text('Henüz bir gruba dahil değilsiniz.'));
            }

            return TabBarView(
              children: [
                    _buildOurDebtsTab(
                      context,
                      ref,
                      groups,
                      currentUserId,
                      currency,
                      exchanger,
                    ),
                    _buildOweUsTab(
                      context,
                      ref,
                      groups,
                      currentUserId,
                      currency,
                      exchanger,
                    ),
                    _buildNetSummaryTab(
                      context,
                      ref,
                      groups,
                      currentUserId,
                      currency,
                      exchanger,
                    ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Hata: $e')),
        ),
      ),
    );
  }

  Widget _buildOurDebtsTab(
    BuildContext context,
    WidgetRef ref,
    List<GroupModel> groups,
    String currentUserId,
    String currency,
    ExchangeRateService exchanger,
  ) {
    final filters = ref.watch(transactionFilterProvider);
    final paidOverrides = ref.watch(groupPaidOverridesProvider);
    final sections = <Widget>[];
    double totalAmount = 0.0;

    for (final group in groups) {
      if (filters.groupId.isNotEmpty && filters.groupId != group.id) continue;
      if (group.id == null) continue;

      final membersAsync = ref.watch(groupMembersProvider(group.id!));
      final transactionsAsync = ref.watch(
        groupTransactionsStreamProvider(group.id!),
      );

      final items = transactionsAsync.maybeWhen(
        data: (transactions) => _collectOurDebts(
          transactions,
          group,
          currentUserId,
          membersAsync,
          filters,
          paidOverrides,
        ),
        orElse: () => const <_DebtLine>[],
      );

      if (items.isEmpty) continue;

      final groupTotal = items.fold<double>(0.0, (p, e) => p + e.amount);
      totalAmount += groupTotal;

      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtRow(
                      title: item.title,
                      subtitle: 'Borçlu olunan kişi: ${item.counterpartyName}',
                      amountText:
                          '$currency${exchanger.convertFromTRY(item.amount, currency).toStringAsFixed(2)}',
                      date: item.date,
                      accentColor: Colors.red.shade700,
                    ),
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
        _buildFilterCard(context, ref, groups),
        const SizedBox(height: 6),
        if (sections.isNotEmpty) ...[
          _SummaryCard(
            label: 'Toplam Borç',
            value:
                '$currency${exchanger.convertFromTRY(totalAmount, currency).toStringAsFixed(2)}',
            accentColor: Colors.red,
          ),
          const SizedBox(height: 12),
          ...sections,
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 56),
            child: Center(child: Text('Bizim borcumuz bulunmuyor.')),
          ),
      ],
    );
  }

  Widget _buildOweUsTab(
    BuildContext context,
    WidgetRef ref,
    List<GroupModel> groups,
    String currentUserId,
    String currency,
    ExchangeRateService exchanger,
  ) {
    final filters = ref.watch(transactionFilterProvider);
    final paidOverrides = ref.watch(groupPaidOverridesProvider);
    final sections = <Widget>[];
    double totalAmount = 0.0;

    for (final group in groups) {
      if (group.id == null) continue;

      final membersAsync = ref.watch(groupMembersProvider(group.id!));
      final transactionsAsync = ref.watch(
        groupTransactionsStreamProvider(group.id!),
      );

      if (filters.groupId.isNotEmpty && filters.groupId != group.id) continue;

      final items = transactionsAsync.maybeWhen(
        data: (transactions) => _collectPeopleOweUs(
          transactions,
          group,
          currentUserId,
          membersAsync,
          filters,
          paidOverrides,
        ),
        orElse: () => const <_DebtLine>[],
      );

      if (items.isEmpty) continue;

      final groupTotal = items.fold<double>(0.0, (p, e) => p + e.amount);
      totalAmount += groupTotal;

      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtRow(
                      title: item.title,
                      subtitle: 'Bize borçlu: ${item.counterpartyName}',
                      amountText:
                          '$currency${exchanger.convertFromTRY(item.amount, currency).toStringAsFixed(2)}',
                      date: item.date,
                      accentColor: Colors.green.shade700,
                    ),
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
        _buildFilterCard(context, ref, groups),
        const SizedBox(height: 6),
        if (sections.isNotEmpty) ...[
          _SummaryCard(
            label: 'Toplam Alacak',
            value:
                '$currency${exchanger.convertFromTRY(totalAmount, currency).toStringAsFixed(2)}',
            accentColor: Colors.green,
          ),
          const SizedBox(height: 12),
          ...sections,
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 56),
            child: Center(child: Text('Bize borcu olan kimse bulunmuyor.')),
          ),
      ],
    );
  }

  Widget _buildNetSummaryTab(
    BuildContext context,
    WidgetRef ref,
    List<GroupModel> groups,
    String currentUserId,
    String currency,
    ExchangeRateService exchanger,
  ) {
    final filters = ref.watch(transactionFilterProvider);
    final sections = <Widget>[];

    for (final group in groups) {
      if (filters.groupId.isNotEmpty && filters.groupId != group.id) continue;
      if (group.id == null) continue;

      final membersAsync = ref.watch(groupMembersProvider(group.id!));
      final balanceMap = ref.watch(balanceEngineProvider(group.id!));

      final settlements = membersAsync.maybeWhen(
        data: (members) => _buildSettlements(
          balanceMap,
          members,
          currentUserId,
        ),
        orElse: () => const <_SettlementLine>[],
      );

      if (settlements.isEmpty) continue;

      final groupTotal = settlements.fold<double>(0.0, (p, e) => p + e.amount);

      sections.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...settlements.map(
                  (settlement) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DebtRow(
                      title: '${settlement.fromName} -> ${settlement.toName}',
                      subtitle: settlement.title,
                      amountText:
                          '$currency${exchanger.convertFromTRY(settlement.amount, currency).toStringAsFixed(2)}',
                      date: settlement.date,
                      accentColor: Colors.deepPurple.shade700,
                    ),
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
        _buildFilterCard(context, ref, groups),
        const SizedBox(height: 6),
        if (sections.isNotEmpty)
          ...sections
        else
          const Padding(
            padding: EdgeInsets.only(top: 56),
            child: Center(child: Text('Netleşecek borç bulunmuyor.')),
          ),
      ],
    );
  }

  Widget _buildFilterCard(BuildContext context, WidgetRef ref, List<GroupModel> groups) {
    final filters = ref.watch(transactionFilterProvider);
    var selectedGroupId = filters.groupId;
    DateTime? selectedStart = filters.start;
    DateTime? selectedEnd = filters.end;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtreler', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedGroupId.isEmpty ? '' : selectedGroupId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Grup',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Hepsi')),
                          ...groups
                              .where((g) => g.id != null)
                              .map((g) => DropdownMenuItem(value: g.id!, child: Text(g.name))),
                        ],
                        onChanged: (value) {
                          setLocalState(() {
                            selectedGroupId = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (picked != null) {
                            setLocalState(() {
                              selectedStart = picked.start;
                              selectedEnd = picked.end;
                            });
                          }
                        },
                        child: Text(
                          selectedStart != null && selectedEnd != null
                              ? '${selectedStart!.day}.${selectedStart!.month}.${selectedStart!.year} - ${selectedEnd!.day}.${selectedEnd!.month}.${selectedEnd!.year}'
                              : 'Tarih seç',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setLocalState(() {
                            selectedGroupId = '';
                            selectedStart = null;
                            selectedEnd = null;
                          });
                          _resetFilters(ref);
                        },
                        icon: const Icon(Icons.filter_alt_off),
                        label: const Text('Sıfırla'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          final notifier = ref.read(transactionFilterProvider.notifier);
                          notifier.clear();
                          notifier.setGroup(selectedGroupId);
                          notifier.setDateRange(selectedStart, selectedEnd);
                        },
                        icon: const Icon(Icons.filter_alt),
                        label: const Text('Filtrele'),
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

  void _resetFilters(WidgetRef ref) {
    ref.read(transactionFilterProvider.notifier).clear();
  }

  List<_DebtLine> _collectOurDebts(
    List<GroupTransactionModel> transactions,
    GroupModel group,
    String currentUserId,
    AsyncValue<List<GroupMemberModel>> membersAsync,
    TransactionFilters filters,
    Map<String, Map<String, bool>> paidOverrides,
  ) {
    final items = <_DebtLine>[];

    for (final tx in transactions) {
      final rawValue = tx.splitData[currentUserId];
      if (rawValue == null) continue;

      final amount = rawValue is Map
          ? (rawValue['amount'] as num?)?.toDouble() ?? 0.0
          : (rawValue as num).toDouble();

      final paid = rawValue is Map
          ? (rawValue['paid'] as bool?) ?? false
          : tx.payerId == currentUserId;

      final effectivePaid = _isParticipantPaid(
        tx,
        currentUserId,
        paidOverrides,
      ) || paid;

      if (amount <= 0 || tx.payerId == currentUserId || effectivePaid) continue;

      // date filter
      if (filters.start != null && tx.createdAt != null) {
        if (tx.createdAt!.isBefore(filters.start!) || tx.createdAt!.isAfter(filters.end!)) continue;
      }

      items.add(
        _DebtLine(
          title: tx.description,
          counterpartyName: _memberName(membersAsync, tx.payerId, currentUserId),
          amount: amount,
          date: tx.createdAt,
          groupName: group.name,
        ),
      );
    }

    return items;
  }

  List<_DebtLine> _collectPeopleOweUs(
    List<GroupTransactionModel> transactions,
    GroupModel group,
    String currentUserId,
    AsyncValue<List<GroupMemberModel>> membersAsync,
    TransactionFilters filters,
    Map<String, Map<String, bool>> paidOverrides,
  ) {
    final items = <_DebtLine>[];

    for (final tx in transactions) {
      if (tx.payerId != currentUserId) continue;

      tx.splitData.forEach((userId, rawValue) {
        if (userId == currentUserId) return;

        final amount = rawValue is Map
            ? (rawValue['amount'] as num?)?.toDouble() ?? 0.0
            : (rawValue as num).toDouble();

        final paid = rawValue is Map
            ? (rawValue['paid'] as bool?) ?? false
            : false;

        final effectivePaid = _isParticipantPaid(
          tx,
          userId,
          paidOverrides,
        ) || paid;

        if (amount <= 0 || effectivePaid) return;

        // date filter
        if (filters.start != null && tx.createdAt != null) {
          if (tx.createdAt!.isBefore(filters.start!) || tx.createdAt!.isAfter(filters.end!)) return;
        }

        items.add(
          _DebtLine(
            title: tx.description,
            counterpartyName: _memberName(membersAsync, userId, currentUserId),
            amount: amount,
            date: tx.createdAt,
            groupName: group.name,
          ),
        );
      });
    }

    return items;
  }

  List<_SettlementLine> _buildSettlements(
    Map<String, double> balances,
    List<GroupMemberModel> members,
    String currentUserId,
  ) {
    final creditors = balances.entries
        .where((e) => e.value > 0.0001)
        .map(
          (e) => _BalanceNode(
            userId: e.key,
            name: _displayName(members, e.key, currentUserId),
            amount: e.value,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final debtors = balances.entries
        .where((e) => e.value < -0.0001)
        .map(
          (e) => _BalanceNode(
            userId: e.key,
            name: _displayName(members, e.key, currentUserId),
            amount: e.value.abs(),
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final settlements = <_SettlementLine>[];
    var creditorIndex = 0;
    var debtorIndex = 0;

    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final amount = creditor.amount < debtor.amount
          ? creditor.amount
          : debtor.amount;

      settlements.add(
        _SettlementLine(
          fromName: debtor.name,
          toName: creditor.name,
          amount: amount,
          title: 'Netleşmiş borç',
          date: null,
        ),
      );

      creditor.amount -= amount;
      debtor.amount -= amount;

      if (creditor.amount <= 0.0001) creditorIndex++;
      if (debtor.amount <= 0.0001) debtorIndex++;
    }

    return settlements;
  }

  String _memberName(
    AsyncValue<List<GroupMemberModel>> membersAsync,
    String userId,
    String currentUserId,
  ) {
    if (userId == currentUserId) return 'Sen';

    return membersAsync.maybeWhen(
      data: (members) => _displayName(members, userId, currentUserId),
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
      final found = members.firstWhere((m) => m.userId == userId);
      return found.username != null && found.username!.isNotEmpty
          ? '@${found.username}'
          : 'Kullanıcı';
    } catch (_) {
      return 'Kullanıcı';
    }
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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (date != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDate(date!),
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
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
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
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ],
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

class _SettlementLine {
  final String fromName;
  final String toName;
  final double amount;
  final String title;
  final DateTime? date;

  const _SettlementLine({
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.title,
    required this.date,
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
