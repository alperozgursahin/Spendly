import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import 'group_model.dart';
import 'group_transaction_model.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(Supabase.instance.client);
});

final groupDataRefreshProvider = StateProvider<int>((ref) => 0);

final groupPaidOverridesProvider =
    StateNotifierProvider<
      GroupPaidOverridesNotifier,
      Map<String, Map<String, bool>>
    >((ref) {
      return GroupPaidOverridesNotifier();
    });

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

final groupTransactionsStreamProvider =
    StreamProvider.family<List<GroupTransactionModel>, String>((ref, groupId) {
      return Supabase.instance.client
          .from('group_transactions')
          .stream(primaryKey: ['id'])
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .map(
            (rows) => rows
                .map(
                  (row) => GroupTransactionModel.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList(),
          );
    });

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

/// Only approved and payment-pending participant shares affect balances.
/// Pending, rejected, and settled participant shares are excluded.
final balanceEngineProvider = Provider.family<Map<String, double>, String>((
  ref,
  groupId,
) {
  final transactions = ref.watch(groupTransactionsStreamProvider(groupId));

  return transactions.maybeWhen(
    data: (items) {
      final balances = <String, double>{};

      for (final transaction in items) {
        transaction.splitData.forEach((participantId, rawValue) {
          if (participantId == transaction.payerId) return;

          final status = participantApprovalStatus(
            transaction.splitData,
            participantId,
            transaction.payerId,
          );

          if (!isDebtCountedStatus(status)) return;

          final amount = _splitAmount(rawValue);
          if (amount <= 0) return;

          balances[participantId] = (balances[participantId] ?? 0) - amount;
          balances[transaction.payerId] =
              (balances[transaction.payerId] ?? 0) + amount;
        });
      }

      return balances;
    },
    orElse: () => <String, double>{},
  );
});

double _splitAmount(dynamic rawValue) {
  if (rawValue is Map) {
    return (rawValue['amount'] as num?)?.toDouble() ?? 0;
  }

  return (rawValue as num?)?.toDouble() ?? 0;
}

class GroupService {
  final SupabaseClient _supabase;

  GroupService(this._supabase);

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
      throw Exception('Only the group admin can perform this action.');
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

  Future<void> addGroupTransaction(GroupTransactionModel transaction) async {
    final insertedRow = await _supabase
        .from('group_transactions')
        .insert(transaction.toJson())
        .select(
          'id, group_id, payer_id, amount, description, split_type, '
          'split_data, status, created_at',
        )
        .single();

    final inserted = GroupTransactionModel.fromJson(
      Map<String, dynamic>.from(insertedRow),
    );

    final recipientIds = inserted.splitData.keys
        .where((userId) => userId != inserted.payerId)
        .toSet()
        .toList();

    if (recipientIds.isEmpty) return;

    await _supabase
        .from('notifications')
        .insert(
          recipientIds
              .map(
                (recipientId) => {
                  'recipient_id': recipientId,
                  'sender_id': inserted.payerId,
                  'group_id': inserted.groupId,
                  'expense_id': inserted.id,
                  'type': 'debt_request',
                  'is_read': false,
                },
              )
              .toList(),
        );
  }

  /// Legacy generic participant update. Do not use this for lifecycle actions.
  Future<void> updateOwnSplitEntry({
    required String transactionId,
    required bool paid,
    required String status,
  }) {
    return _supabase.rpc(
      'update_own_group_transaction_split',
      params: {
        'p_transaction_id': transactionId,
        'p_paid': paid,
        'p_status': status,
      },
    );
  }

  /// Debtor: pending -> approved.
  Future<void> acknowledgeDebtParticipant(String transactionId) {
    return _supabase.rpc(
      'acknowledge_debt_participant',
      params: {'p_transaction_id': transactionId},
    );
  }

  /// Debtor: approved -> payment_pending.
  Future<void> markPaymentSent(String transactionId) {
    return _supabase.rpc(
      'mark_payment_sent',
      params: {'p_transaction_id': transactionId},
    );
  }

  /// Creditor: payment_pending -> settled.
  Future<void> confirmPaymentReceived({
    required String transactionId,
    required String participantId,
  }) {
    return _supabase.rpc(
      'confirm_payment_received',
      params: {
        'p_transaction_id': transactionId,
        'p_participant_id': participantId,
      },
    );
  }

  /// Kept because the current approvals screen still offers rejection.
  Future<void> rejectDebtParticipant(String transactionId) {
    return _supabase.rpc(
      'reject_debt_participant',
      params: {'p_transaction_id': transactionId},
    );
  }

  /// Backward-compatible alias for any older callers.
  Future<void> approveDebtParticipant(String transactionId) {
    return acknowledgeDebtParticipant(transactionId);
  }

  /// Payer: moves an expense to the archive tab once every participant has
  /// settled. Rejected server-side if any share isn't settled yet.
  Future<void> archiveGroupTransaction(String transactionId) {
    return _supabase.rpc(
      'archive_group_transaction',
      params: {'p_transaction_id': transactionId},
    );
  }
}

class GroupPaidOverridesNotifier
    extends StateNotifier<Map<String, Map<String, bool>>> {
  GroupPaidOverridesNotifier() : super(const {});

  void setPaid(String transactionId, String participantId, bool paid) {
    final updatedState = Map<String, Map<String, bool>>.from(state);
    final transactionOverrides = Map<String, bool>.from(
      updatedState[transactionId] ?? const {},
    );

    transactionOverrides[participantId] = paid;
    updatedState[transactionId] = transactionOverrides;
    state = updatedState;
  }

  void clearTransaction(String transactionId) {
    final updatedState = Map<String, Map<String, bool>>.from(state);
    updatedState.remove(transactionId);
    state = updatedState;
  }

  void clear() {
    state = const {};
  }
}
