import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/analytics_service.dart';
import 'transaction_model.dart';
import '../auth/auth_provider.dart';

final transactionServiceProvider = Provider<TransactionService>((ref) {
  final supabase = Supabase.instance.client;
  return TransactionService(supabase, ref.watch(analyticsServiceProvider));
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
          balance += t.baseAmount;
        } else {
          balance -= t.baseAmount;
        }
      }
      return balance;
    },
    orElse: () => 0.0,
  );
});

class TransactionService {
  final SupabaseClient _supabase;
  final AnalyticsService _analytics;

  TransactionService(this._supabase, this._analytics);

  Future<List<TransactionModel>> getTransactions(String userId) async {
    final response = await _supabase
        .from('transactions')
        .select(
          'id, user_id, group_id, amount, original_amount, currency_code, '
          'base_amount, base_currency_code, exchange_rate, rate_source, '
          'rate_locked_at, category, date, type, created_at',
        )
        .eq('user_id', userId)
        .order('date', ascending: false);

    return response.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    // RLS enforces ownership. The compatibility trigger keeps `amount` equal
    // to base_amount until the legacy column is removed.
    await _supabase.from('transactions').insert(transaction.toJson());
    if (transaction.type == 'expense') {
      await _analytics.expenseAdded(scope: ExpenseAnalyticsScope.personal);
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }
}
