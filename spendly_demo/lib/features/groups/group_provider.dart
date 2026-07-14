import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group_model.dart';
import 'group_transaction_model.dart';
import '../auth/auth_provider.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(Supabase.instance.client);
});

final groupDataRefreshProvider = StateProvider<int>((ref) => 0);

final groupPaidOverridesProvider = StateNotifierProvider<
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

final groupMembersProvider =
    FutureProvider.family<List<GroupMemberModel>, String>((ref, groupId) async {
      final service = ref.watch(groupServiceProvider);
      return service.getGroupMembers(groupId);
    });

final groupTransactionsStreamProvider =
    StreamProvider.family<List<GroupTransactionModel>, String>((ref, groupId) {
      final supabase = Supabase.instance.client;
      return supabase
          .from('group_transactions')
          .stream(primaryKey: ['id'])
          .eq('group_id', groupId)
          .order('created_at', ascending: false)
          .map(
            (data) => data
                .map((json) => GroupTransactionModel.fromJson(json))
                .toList(),
          );
    });

final balanceEngineProvider = Provider.family<Map<String, double>, String>((
  ref,
  groupId,
) {
  final transactionsAsync = ref.watch(groupTransactionsStreamProvider(groupId));
  final paidOverrides = ref.watch(groupPaidOverridesProvider);

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      Map<String, double> balances = {};

      for (var tx in transactions) {
        tx.splitData.forEach((userId, owedAmount) {
          if (userId == tx.payerId) {
            return;
          }

          if (owedAmount is! num && owedAmount is! Map) {
            return;
          }

          // A share that's still awaiting the counterparty's approval (or
          // was rejected by them) isn't a finalized debt yet, so it must not
          // move the group balance.
          if (participantApprovalStatus(tx.splitData, userId, tx.payerId) !=
              DebtApprovalStatus.approved) {
            return;
          }

          final amount = owedAmount is Map
              ? (owedAmount['amount'] as num?)?.toDouble() ?? 0.0
              : (owedAmount as num).toDouble();

          final paid = _isParticipantPaid(
            tx,
            userId,
            paidOverrides,
          );

          if (paid) return;

          balances[userId] = (balances[userId] ?? 0.0) - amount;
          balances[tx.payerId] = (balances[tx.payerId] ?? 0.0) + amount;
        });
      }
      return balances;
    },
    orElse: () => {},
  );
});

class GroupService {
  final SupabaseClient _supabase;

  GroupService(this._supabase);

  Future<List<GroupModel>> getUserGroups(String userId) async {
    final response = await _supabase
        .from('group_members')
        .select('groups (*)')
        .eq('user_id', userId);

    return response
        .map(
          (json) => GroupModel.fromJson(json['groups'] as Map<String, dynamic>),
        )
        .toList();
  }

  Future<GroupModel> createGroup(String name, String userId) async {
    // Insert Group
    final groupResponse = await _supabase
        .from('groups')
        .insert({'name': name, 'created_by': userId})
        .select()
        .single();

    final group = GroupModel.fromJson(groupResponse);

    // Add creator as member
    await _supabase.from('group_members').insert({
      'group_id': group.id,
      'user_id': userId,
    });

    return group;
  }

  Future<void> addMemberToGroup(String groupId, String userId) async {
    await _supabase.from('group_members').insert({
      'group_id': groupId,
      'user_id': userId,
    });
  }

  Future<List<GroupMemberModel>> getGroupMembers(String groupId) async {
    final response = await _supabase
        .from('group_members')
        .select('*, profiles(username, avatar_url)')
        .eq('group_id', groupId);

    return response.map((json) => GroupMemberModel.fromJson(json)).toList();
  }

  Future<void> addGroupTransaction(GroupTransactionModel tx) async {
    await _supabase.from('group_transactions').insert(tx.toJson());
  }

  // Updates only the calling user's own entry within a transaction's
  // split_data (their paid state and/or approval status). Goes through the
  // `update_own_group_transaction_split` RPC (see
  // supabase/migrations/20260714_group_transaction_participant_update.sql)
  // rather than a plain `.update()`, because the base RLS policy on
  // group_transactions only allows the payer to modify the row — a
  // non-payer participant approving/rejecting or settling their own share
  // would otherwise be silently blocked (Postgrest reports success with
  // zero rows changed, no exception).
  Future<void> updateOwnSplitEntry({
    required String transactionId,
    required bool paid,
    required String status,
  }) async {
    await _supabase.rpc(
      'update_own_group_transaction_split',
      params: {
        'p_transaction_id': transactionId,
        'p_paid': paid,
        'p_status': status,
      },
    );
  }
}

class GroupPaidOverridesNotifier
    extends StateNotifier<Map<String, Map<String, bool>>> {
  GroupPaidOverridesNotifier() : super(const {});

  void setPaid(String transactionId, String participantId, bool paid) {
    final updated = Map<String, Map<String, bool>>.from(state);
    final transactionOverrides = Map<String, bool>.from(
      updated[transactionId] ?? const {},
    );
    transactionOverrides[participantId] = paid;
    updated[transactionId] = transactionOverrides;
    state = updated;
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

