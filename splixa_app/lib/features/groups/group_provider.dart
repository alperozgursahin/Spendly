import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics_service.dart';
import '../../core/friendly_error.dart';
import '../auth/auth_provider.dart';
import 'financial_models.dart';
import 'group_model.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(
    Supabase.instance.client,
    ref.watch(analyticsServiceProvider),
  );
});

final groupDataRefreshProvider = StateProvider<int>((ref) => 0);

final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final service = ref.watch(groupServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];

  return service.getUserGroups(userId);
});

final groupByIdProvider = FutureProvider.family<GroupModel?, String>((
  ref,
  groupId,
) {
  final service = ref.watch(groupServiceProvider);
  return service.getGroup(groupId);
});

final groupMembersProvider =
    FutureProvider.family<List<GroupMemberModel>, String>((ref, groupId) {
      final service = ref.watch(groupServiceProvider);
      return service.getGroupMembers(groupId);
    });

/// Canonical group-expense source for new UI code.
final groupExpensesStreamProvider =
    StreamProvider.family<List<ExpenseWithShares>, String>((ref, groupId) {
      ref.watch(groupDataRefreshProvider);
      return ref.watch(groupServiceProvider).watchGroupExpenses(groupId);
    });

final groupSettlementsProvider =
    FutureProvider.family<List<Settlement>, String>((ref, groupId) {
      ref.watch(groupDataRefreshProvider);
      ref.watch(groupExpensesStreamProvider(groupId));
      return ref.watch(groupServiceProvider).getGroupSettlements(groupId);
    });

final groupBalancesProvider = FutureProvider.family<List<GroupBalance>, String>(
  (ref, groupId) {
    ref.watch(groupDataRefreshProvider);
    ref.watch(groupExpensesStreamProvider(groupId));
    return ref.watch(groupServiceProvider).getGroupBalances(groupId);
  },
);

final groupMessagesStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, groupId) {
      return Supabase.instance.client
          .from('group_messages')
          .stream(primaryKey: ['id'])
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .map((rows) => rows);
    });

/// Each user has at most one row per group (RLS only exposes the caller's
/// own row), so this is null until they've opened that group's chat once.
final groupChatReadStreamProvider = StreamProvider.family<DateTime?, String>((
  ref,
  groupId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  return Supabase.instance.client
      .from('group_chat_reads')
      .stream(primaryKey: ['group_id', 'user_id'])
      .eq('group_id', groupId)
      .map((rows) {
        if (rows.isEmpty) return null;
        final value = rows.first['last_read_at'] as String?;
        return value == null ? null : DateTime.parse(value).toUtc();
      });
});

/// Home-list badge count: new messages plus new expenses added by somebody
/// else since the user last opened this group.
final unreadGroupActivityCountProvider = Provider.family<int, String>((
  ref,
  groupId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final messages = ref.watch(groupMessagesStreamProvider(groupId));
  final expenses = ref.watch(groupExpensesStreamProvider(groupId));
  final lastRead = ref.watch(groupChatReadStreamProvider(groupId));
  final cutoff = lastRead.maybeWhen(data: (value) => value, orElse: () => null);

  final unreadMessages = messages.maybeWhen(
    data: (items) => items.where((item) {
      if (item['sender_id'] == userId) return false;
      final createdAt = DateTime.tryParse(item['created_at'] as String? ?? '');
      return createdAt != null &&
          (cutoff == null || createdAt.toUtc().isAfter(cutoff));
    }).length,
    orElse: () => 0,
  );

  final unreadTransactions = expenses.maybeWhen(
    data: (items) => items.where((item) {
      final expense = item.expense;
      if (expense.payerId == userId) return false;
      return cutoff == null || expense.createdAt.toUtc().isAfter(cutoff);
    }).length,
    orElse: () => 0,
  );

  return unreadMessages + unreadTransactions;
});

/// Messages from other members created after the caller's last-read cutoff.
final unreadGroupMessagesCountProvider = Provider.family<int, String>((
  ref,
  groupId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;

  final messages = ref.watch(groupMessagesStreamProvider(groupId));
  final lastRead = ref.watch(groupChatReadStreamProvider(groupId));

  return messages.maybeWhen(
    data: (msgs) {
      final cutoff = lastRead.maybeWhen(data: (v) => v, orElse: () => null);
      return msgs.where((m) {
        if (m['sender_id'] == userId) return false;
        if (cutoff == null) return true;
        return DateTime.parse(
          m['created_at'] as String,
        ).toUtc().isAfter(cutoff);
      }).length;
    },
    orElse: () => 0,
  );
});

Future<void> markGroupChatRead(String groupId, String userId) {
  return Supabase.instance.client.from('group_chat_reads').upsert({
    'group_id': groupId,
    'user_id': userId,
    'last_read_at': DateTime.now().toUtc().toIso8601String(),
  }, onConflict: 'group_id,user_id');
}

class GroupService {
  final SupabaseClient _supabase;
  final AnalyticsService _analytics;

  GroupService(this._supabase, this._analytics);

  Stream<List<ExpenseWithShares>> watchGroupExpenses(String groupId) {
    return _supabase
        .from('expenses')
        .stream(primaryKey: ['id'])
        .eq('group_id', groupId)
        .order('created_at', ascending: false)
        .asyncMap(_hydrateExpenses);
  }

  Future<List<ExpenseWithShares>> getGroupExpenses(String groupId) async {
    final rows = await _supabase
        .from('expenses')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return _hydrateExpenses(rows);
  }

  Future<List<ExpenseWithShares>> _hydrateExpenses(
    List<Map<String, dynamic>> rows,
  ) async {
    final expenses = rows
        .map((row) => Expense.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    if (expenses.isEmpty) return const [];

    final shareRows = await _supabase
        .from('expense_shares')
        .select()
        .inFilter('expense_id', expenses.map((expense) => expense.id).toList());
    final shares = shareRows
        .map((row) => ExpenseShare.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);

    final sharesByExpense = <String, List<ExpenseShare>>{};
    for (final share in shares) {
      sharesByExpense.putIfAbsent(share.expenseId, () => []).add(share);
    }

    return expenses
        .map(
          (expense) => ExpenseWithShares(
            expense: expense,
            shares: List.unmodifiable(sharesByExpense[expense.id] ?? const []),
          ),
        )
        .toList(growable: false);
  }

  Future<List<Settlement>> getGroupSettlements(String groupId) async {
    final rows = await _supabase
        .from('settlements')
        .select()
        .eq('group_id', groupId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => Settlement.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<GroupBalance>> getGroupBalances(String groupId) async {
    final rows = await _supabase
        .from('group_balances_v1')
        .select('group_id, user_id, currency_code, balance')
        .eq('group_id', groupId);
    return rows
        .map((row) => GroupBalance.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<Expense> createExpense(ExpenseDraft draft) async {
    final response = await _supabase.rpc(
      'create_expense_v1',
      params: draft.toRpcParameters(),
    );
    final expense = Expense.fromJson(
      _singleRpcRow(response, 'create_expense_v1'),
    );
    await _analytics.expenseAdded(scope: ExpenseAnalyticsScope.group);
    return expense;
  }

  Future<void> acknowledgeExpenseShare(String expenseId) async {
    await _supabase.rpc(
      'acknowledge_expense_share_v1',
      params: {'p_expense_id': expenseId},
    );
    await _analytics.ledgerActionCompleted(
      action: LedgerAnalyticsAction.acknowledged,
    );
  }

  Future<void> markExpensePaymentSent(String expenseId) async {
    await _supabase.rpc(
      'mark_expense_payment_sent_v1',
      params: {'p_expense_id': expenseId},
    );
    await _analytics.ledgerActionCompleted(
      action: LedgerAnalyticsAction.paymentSent,
    );
  }

  Future<Settlement> confirmExpensePayment({
    required String expenseId,
    required String participantId,
  }) async {
    final response = await _supabase.rpc(
      'confirm_expense_payment_v1',
      params: {'p_expense_id': expenseId, 'p_participant_id': participantId},
    );
    final settlement = Settlement.fromJson(
      _singleRpcRow(response, 'confirm_expense_payment_v1'),
    );
    await _analytics.ledgerActionCompleted(
      action: LedgerAnalyticsAction.paymentConfirmed,
    );
    return settlement;
  }

  Future<void> rejectExpenseShare(String expenseId) async {
    await _supabase.rpc(
      'reject_expense_share_v1',
      params: {'p_expense_id': expenseId},
    );
    await _analytics.ledgerActionCompleted(
      action: LedgerAnalyticsAction.rejected,
    );
  }

  Future<void> archiveExpense(String expenseId) async {
    await _supabase.rpc(
      'archive_expense_v1',
      params: {'p_expense_id': expenseId},
    );
    await _analytics.ledgerActionCompleted(
      action: LedgerAnalyticsAction.archived,
    );
  }

  Future<GroupModel?> getGroup(String groupId) async {
    final row = await _supabase
        .from('groups')
        .select()
        .eq('id', groupId)
        .maybeSingle();

    if (row == null) return null;
    return GroupModel.fromJson(Map<String, dynamic>.from(row));
  }

  /// Only the group creator can do this (enforced by RLS); the group's
  /// members, transactions and notifications cascade-delete with it.
  Future<void> deleteGroup(String groupId) {
    return _supabase.from('groups').delete().eq('id', groupId);
  }

  /// Removes the given member's own row from the group (RLS only allows a
  /// user to delete their own membership, or the group creator to delete
  /// any). The creator should use [deleteGroup] instead of leaving.
  Future<void> leaveGroup(String groupId, String userId) {
    return _supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  Future<List<GroupModel>> getUserGroups(String userId) async {
    final rows = await _supabase
        .from('group_members')
        .select('groups (*)')
        .eq('user_id', userId);

    return rows
        .where((row) => row['groups'] != null)
        .map(
          (row) => GroupModel.fromJson(
            Map<String, dynamic>.from(row['groups'] as Map),
          ),
        )
        .toList();
  }

  Future<GroupModel> createGroup(String name, String userId) async {
    final row = await _supabase
        .from('groups')
        .insert({'name': name, 'created_by': userId})
        .select()
        .single();

    final group = GroupModel.fromJson(Map<String, dynamic>.from(row));

    await _supabase.from('group_members').insert({
      'group_id': group.id,
      'user_id': userId,
    });

    await _analytics.groupCreated();

    return group;
  }

  Future<void> addMemberToGroup(String groupId, String userId) {
    return _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });
  }

  Future<void> addMemberAsAdmin({
    required String groupId,
    required String memberId,
    required String actorId,
  }) async {
    await _assertGroupAdmin(groupId, actorId);
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': memberId,
    });
  }

  Future<void> removeMemberAsAdmin({
    required String groupId,
    required String memberId,
    required String actorId,
  }) async {
    await _assertGroupAdmin(groupId, actorId);
    await _supabase
        .from('group_members')
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', memberId);
  }

  Future<void> updateGroupAvatar({
    required String groupId,
    required String actorId,
    required String avatarUrl,
  }) async {
    await _assertGroupAdmin(groupId, actorId);
    await _supabase
        .from('groups')
        .update({'avatar_url': avatarUrl})
        .eq('id', groupId);
  }

  Future<void> _assertGroupAdmin(String groupId, String actorId) async {
    final group = await _supabase
        .from('groups')
        .select('created_by')
        .eq('id', groupId)
        .maybeSingle();
    if (group == null || group['created_by'] != actorId) {
      throw const FriendlyException('group_admin_only');
    }
  }

  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final rows = await _supabase
        .from('group_members')
        .select('*, profiles(username, avatar_url)')
        .eq('group_id', groupId);

    return rows
        .map((row) => GroupMemberModel.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}

Map<String, dynamic> _singleRpcRow(Object? response, String functionName) {
  if (response is Map) return Map<String, dynamic>.from(response);
  if (response is List && response.length == 1 && response.single is Map) {
    return Map<String, dynamic>.from(response.single as Map);
  }
  throw StateError('$functionName returned an unexpected response');
}
