import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'group_model.dart';
import 'group_transaction_model.dart';
import '../auth/auth_provider.dart';
import '../transactions/transaction_model.dart';

final groupServiceProvider = Provider<GroupService>((ref) {
  return GroupService(Supabase.instance.client);
});

final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final service = ref.watch(groupServiceProvider);
  final userId = ref.watch(authClientProvider).currentUser?.id;
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

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      Map<String, double> balances = {};

      for (var tx in transactions) {
        balances[tx.payerId] = (balances[tx.payerId] ?? 0.0) + tx.amount;

        tx.splitData.forEach((userId, owedAmount) {
          if (owedAmount is! num && owedAmount is! Map) {
            return;
          }

          final amount = owedAmount is Map
              ? (owedAmount['amount'] as num?)?.toDouble() ?? 0.0
              : (owedAmount as num).toDouble();

          balances[userId] = (balances[userId] ?? 0.0) - amount;
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

  Future<void> updateGroupTransactionSplitData(
    String transactionId,
    Map<String, dynamic> splitData,
  ) async {
    await _supabase
        .from('group_transactions')
        .update({'split_data': splitData})
        .eq('id', transactionId);
  }
}
