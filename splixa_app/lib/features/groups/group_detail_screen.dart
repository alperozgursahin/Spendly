import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_strings.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import '../filters/filters_provider.dart';
import '../profile/currency_provider.dart';
import '../profile/exchange_rate_provider.dart';
import 'add_expense_sheet.dart';
import 'group_model.dart';
import 'group_chat_screen.dart';
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

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  String? _activeTransactionId;
  final Set<String> _processingActions = <String>{};
  late final TabController _tabController;

  static const _tabBuckets = [
    ExpenseBucket.pendingApproval,
    ExpenseBucket.active,
    ExpenseBucket.archived,
  ];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: _tabBuckets.length + 1, vsync: this)
      ..addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.invalidate(groupTransactionsStreamProvider(widget.groupId));
      ref.invalidate(groupMembersProvider(widget.groupId));
      ref.invalidate(balanceEngineProvider(widget.groupId));
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) return;
      try {
        await markGroupChatRead(widget.groupId, userId);
        if (mounted) {
          ref.invalidate(groupChatReadStreamProvider(widget.groupId));
        }
      } catch (error) {
        debugPrint('markGroupChatRead failed: $error');
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(groupDataRefreshProvider);

    final currentUserId = ref.watch(currentUserProvider)?.id ?? '';
    final currency = ref.watch(currencyProvider);
    final exchanger = ref.watch(exchangeRateProvider);
    final members = ref.watch(groupMembersProvider(widget.groupId));
    final group = ref.watch(groupByIdProvider(widget.groupId));
    final groupAvatarUrl = group.valueOrNull?.avatarUrl;
    final isAdmin = group.valueOrNull?.createdBy == currentUserId;
    final unreadChatCount = ref.watch(
      unreadGroupMessagesCountProvider(widget.groupId),
    );
    final transactions = ref.watch(
      groupTransactionsStreamProvider(widget.groupId),
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
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
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundImage: groupAvatarUrl?.isNotEmpty == true
                    ? NetworkImage(groupAvatarUrl!)
                    : null,
                child: groupAvatarUrl?.isNotEmpty == true
                    ? null
                    : Icon(
                        Icons.group,
                        color: Theme.of(context).colorScheme.primary,
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
                        '${items.length} ${tr(ref, 'groups_participants_suffix')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      loading: () => Text(
                        tr(ref, 'common_loading'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      error: (_, __) => Text(
                        tr(ref, 'groups_participants_load_error'),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
            tooltip: tr(ref, 'groups_chat_tooltip'),
            icon: Badge(
              isLabelVisible: unreadChatCount > 0,
              label: Text('$unreadChatCount'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            onPressed: () => _tabController.animateTo(_tabBuckets.length),
          ),
          if (isAdmin)
            IconButton(
              tooltip: tr(ref, 'groups_invite_friend_tooltip'),
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
          if (_tabController.index < _tabBuckets.length) ...[
            _buildBalanceHeader(
              currentUserId: currentUserId,
              currency: currency,
              exchanger: exchanger,
            ),
            _buildFilterCard(currentUserId),
          ],
          Builder(
            builder: (context) {
              final filtered = _filteredTransactions(
                transactions.valueOrNull ?? const <GroupTransactionModel>[],
              );
              final counts = {
                for (final bucket in _tabBuckets)
                  bucket: filtered
                      .where((item) => computeExpenseBucket(item) == bucket)
                      .length,
              };
              return Material(
                color: Theme.of(context).cardTheme.color,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  tabs: [
                    _buildTabLabel(
                      tr(ref, 'groups_tab_pending'),
                      counts[ExpenseBucket.pendingApproval]!,
                    ),
                    _buildTabLabel(
                      tr(ref, 'groups_tab_active'),
                      counts[ExpenseBucket.active]!,
                    ),
                    _buildTabLabel(
                      tr(ref, 'groups_tab_archived'),
                      counts[ExpenseBucket.archived]!,
                    ),
                    Tab(
                      child: Badge(
                        isLabelVisible: unreadChatCount > 0,
                        label: Text('$unreadChatCount'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 18),
                            SizedBox(width: 7),
                            Text('Chat'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ..._tabBuckets.map((bucket) {
                  if (transactions.isLoading && !transactions.hasValue) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (transactions.hasError && !transactions.hasValue) {
                    return Center(
                      child: Text(friendlyErrorMessage(transactions.error!)),
                    );
                  }
                  final filtered = _filteredTransactions(
                    transactions.valueOrNull ?? const <GroupTransactionModel>[],
                  );
                  final bucketItems = filtered
                      .where((t) => computeExpenseBucket(t) == bucket)
                      .toList();

                  if (bucketItems.isEmpty) {
                    return Center(child: Text(_emptyBucketMessage(bucket)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: bucketItems.length,
                    itemBuilder: (context, index) {
                      final transaction = bucketItems[index];

                      return _buildTransactionCard(
                        transaction: transaction,
                        currentUserId: currentUserId,
                        currency: currency,
                        exchanger: exchanger,
                        members: members,
                      );
                    },
                  );
                }),
                GroupChatView(groupId: widget.groupId),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == _tabBuckets.length
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.receipt_long),
              label: Text(tr(ref, 'groups_add_expense')),
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

  Widget _buildTabLabel(String label, int count) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('$label ($count)', maxLines: 1, softWrap: false),
      ),
    );
  }

  String _emptyBucketMessage(ExpenseBucket bucket) {
    switch (bucket) {
      case ExpenseBucket.pendingApproval:
        return tr(ref, 'groups_empty_pending');
      case ExpenseBucket.active:
        return tr(ref, 'groups_empty_active');
      case ExpenseBucket.archived:
        return tr(ref, 'groups_empty_archived');
    }
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
        ? tr(ref, 'common_you')
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
            color: isExpanded
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$payerName ${tr(ref, 'groups_paid_verb')}',
                          style: TextStyle(
                            fontSize: 14,
                            color: transaction.payerId == currentUserId
                                ? Colors.green.shade700
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$currency${exchanger.convertFromTRY(transaction.amount, currency).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (transaction.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  _formatDate(transaction.createdAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
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
              if (transactionId.isNotEmpty &&
                  transaction.payerId == currentUserId &&
                  transaction.archivedAt == null &&
                  allParticipantsSettled(transaction)) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: _processingActions.contains('$transactionId:archive')
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : OutlinedButton.icon(
                          onPressed: () => _archiveTransaction(transactionId),
                          icon: const Icon(Icons.archive_outlined, size: 18),
                          label: Text(tr(ref, 'groups_archive_all_button')),
                        ),
                ),
              ],
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
        ? tr(ref, 'common_you')
        : _memberName(members, participantId, currentUserId);

    final amountLabel =
        '$participantName: $currency${exchanger.convertFromTRY(amount, currency).toStringAsFixed(2)}';

    if (isPayer) {
      final primary = Theme.of(context).colorScheme.primary;
      return _statusChip(
        amountLabel: amountLabel,
        label: tr(ref, 'groups_status_payer'),
        icon: Icons.account_balance_wallet_rounded,
        backgroundColor: Color.lerp(Colors.white, primary, 0.10)!,
        borderColor: Color.lerp(Colors.white, primary, 0.30)!,
        textColor: Color.lerp(Colors.black, primary, 0.55)!,
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
        actionLabel = tr(ref, 'groups_action_approve');
        actionIcon = Icons.check_rounded;
        onActionPressed = () => _runLifecycleAction(
          transactionId: transactionId,
          participantId: participantId,
          status: status,
        );
      } else if (status == DebtApprovalStatus.approved && isCurrentUser) {
        actionLabel = tr(ref, 'groups_action_mark_paid');
        actionIcon = Icons.payments_rounded;
        onActionPressed = () => _runLifecycleAction(
          transactionId: transactionId,
          participantId: participantId,
          status: status,
        );
      } else if (status == DebtApprovalStatus.paymentPending &&
          transaction.payerId == currentUserId) {
        actionLabel = tr(ref, 'groups_action_confirm_payment');
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
          label: tr(ref, 'groups_status_pending'),
          icon: Icons.hourglass_top_rounded,
          backgroundColor: _tint(_statusWarning, 0.12),
          borderColor: _tint(_statusWarning, 0.35),
          textColor: _shade(_statusWarning, 0.35),
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onActionPressed: onActionPressed,
          isBusy: isBusy,
        );

      case DebtApprovalStatus.approved:
        return _statusChip(
          amountLabel: amountLabel,
          label: isCurrentUser
              ? tr(ref, 'groups_status_approved_self')
              : tr(ref, 'groups_status_active_debt'),
          icon: Icons.verified_rounded,
          backgroundColor: _tint(_statusActive, 0.10),
          borderColor: _tint(_statusActive, 0.30),
          textColor: _shade(_statusActive, 0.25),
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onActionPressed: onActionPressed,
          isBusy: isBusy,
        );

      case DebtApprovalStatus.paymentPending:
        // Kept in the same blue family as "approved" (still an active,
        // in-progress debt) instead of a 5th distinct hue, to reduce how
        // many colors a user has to learn to read the debt status.
        return _statusChip(
          amountLabel: amountLabel,
          label: transaction.payerId == currentUserId
              ? tr(ref, 'groups_status_payment_pending_payer')
              : tr(ref, 'groups_status_payment_reported'),
          icon: Icons.schedule_send_rounded,
          backgroundColor: _tint(_statusActive, 0.14),
          borderColor: _tint(_statusActive, 0.38),
          textColor: _shade(_statusActive, 0.25),
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onActionPressed: onActionPressed,
          isBusy: isBusy,
        );

      case DebtApprovalStatus.settled:
        return _statusChip(
          amountLabel: amountLabel,
          label: tr(ref, 'groups_status_settled'),
          icon: Icons.verified_rounded,
          backgroundColor: _tint(_statusGood, 0.12),
          borderColor: _tint(_statusGood, 0.35),
          textColor: _shade(_statusGood, 0.15),
        );

      case DebtApprovalStatus.rejected:
        return _statusChip(
          amountLabel: amountLabel,
          label: tr(ref, 'groups_status_rejected'),
          icon: Icons.block_rounded,
          backgroundColor: _tint(_statusCritical, 0.10),
          borderColor: _tint(_statusCritical, 0.30),
          textColor: _shade(_statusCritical, 0.20),
        );
    }
  }

  // Validated status palette (see dataviz skill's references/palette.md).
  // Deliberately shares hues with statistics_screen.dart's pie chart colors
  // so status chips and charts read as one cohesive family.
  static const _statusWarning = Color(0xFFD97706);
  static const _statusActive = Color(0xFF2563EB);
  static const _statusGood = Color(0xFF059669);
  static const _statusCritical = Color(0xFFDC2626);

  Color _tint(Color base, double amount) =>
      Color.lerp(Colors.white, base, amount)!;

  Color _shade(Color base, double amount) =>
      Color.lerp(base, Colors.black, amount)!;

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
          SnackBar(content: Text(tr(ref, 'groups_action_failed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingActions.remove(actionKey));
      }
    }
  }

  Future<void> _archiveTransaction(String transactionId) async {
    final actionKey = '$transactionId:archive';

    if (_processingActions.contains(actionKey)) return;

    setState(() => _processingActions.add(actionKey));

    try {
      final service = ref.read(groupServiceProvider);
      await service.archiveGroupTransaction(transactionId);

      ref.invalidate(groupTransactionsStreamProvider(widget.groupId));
      ref.read(groupDataRefreshProvider.notifier).state++;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr(ref, 'groups_archive_failed'))),
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

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: Theme.of(context).cardTheme.color,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(ref, 'groups_balance_title'),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              tr(ref, 'groups_no_active_debt'),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: entries.map((entry) {
                  final isPositive = entry.value > 0;
                  final displayName = entry.key == currentUserId
                      ? tr(ref, 'common_you')
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
                      '$displayName ${isPositive ? tr(ref, "groups_creditor_label") : tr(ref, "groups_debtor_label")}: '
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    tr(ref, 'groups_filter_payer_label'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedPersonId,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: [
                          DropdownMenuItem(
                            value: '',
                            child: Text(tr(ref, 'common_all')),
                          ),
                          ...memberList.map(
                            (member) => DropdownMenuItem(
                              value: member.userId,
                              child: Text(
                                member.userId == currentUserId
                                    ? tr(ref, 'common_you')
                                    : (member.username == null ||
                                              member.username!.isEmpty
                                          ? tr(ref, 'common_user')
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
                            ? tr(ref, 'common_date')
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
                        child: Text(tr(ref, 'common_reset')),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.filter_alt),
                        label: Text(tr(ref, 'common_filter')),
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
    if (userId == currentUserId) return tr(ref, 'common_you');

    return members.maybeWhen(
      data: (items) {
        try {
          final member = items.firstWhere((item) => item.userId == userId);
          final username = member.username?.trim();

          return username == null || username.isEmpty
              ? tr(ref, 'common_user')
              : '@$username';
        } catch (_) {
          return tr(ref, 'common_user');
        }
      },
      orElse: () => tr(ref, 'common_user'),
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
