import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'transaction_model.dart';
import '../auth/auth_provider.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final supabase = Supabase.instance.client;
  return TransactionService(supabase);
});

final transactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final service = ref.watch(transactionServiceProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return [];

  return service.getTransactions(userId);
});

final netBalanceProvider = Provider<double>((ref) {
  final transactionsAsync = ref.watch(transactionsProvider);

  return transactionsAsync.maybeWhen(
    data: (transactions) {
      double balance = 0.0;
      for (var t in transactions) {
        if (t.type == 'income') {
          balance += t.amount;
        } else {
          balance -= t.amount;
        }
      }
      return balance;
    },
    orElse: () => 0.0,
  );
});

class TransactionService {
  final SupabaseClient _supabase;

  TransactionService(this._supabase);

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return response.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _supabase.from('transactions').insert(transaction.toJson());
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }
}
