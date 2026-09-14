import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../transactions/transaction_provider.dart';

/// A user's own spending category. Name only by design: people were typing an
/// emoji into the name field anyway, so a separate emoji box and a colour
/// picker were two extra decisions that bought nothing. The `emoji` and
/// `color_value` columns still exist and still hold whatever older rows put
/// there; they are simply no longer read or written.
class CustomCategory {
  const CustomCategory({required this.id, required this.name});
  final String id;
  final String name;

  factory CustomCategory.fromJson(Map<String, dynamic> json) =>
      CustomCategory(id: json['id'] as String, name: json['name'] as String);
}

class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.title,
    required this.category,
    required this.originalAmount,
    required this.currencyCode,
    required this.baseAmount,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.rateSource,
    required this.rateLockedAt,
    required this.frequency,
    required this.timezone,
    required this.nextRunAt,
    required this.isActive,
  });
  final String id;
  final String title;
  final String category;
  final double originalAmount;
  final String currencyCode;
  final double baseAmount;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String rateSource;
  final DateTime rateLockedAt;
  final String frequency;
  final String timezone;
  final DateTime nextRunAt;
  final bool isActive;

  factory RecurringExpense.fromJson(Map<String, dynamic> json) =>
      RecurringExpense(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        originalAmount: (json['original_amount'] as num).toDouble(),
        currencyCode: json['currency_code'] as String,
        baseAmount: (json['base_amount'] as num).toDouble(),
        baseCurrencyCode: json['base_currency_code'] as String,
        exchangeRate: (json['exchange_rate'] as num).toDouble(),
        rateSource: json['rate_source'] as String,
        rateLockedAt: DateTime.parse(json['rate_locked_at'] as String).toUtc(),
        frequency: json['frequency'] as String,
        timezone: json['timezone'] as String,
        nextRunAt: DateTime.parse(json['next_run_at'] as String).toUtc(),
        isActive: json['is_active'] as bool? ?? true,
      );
}

final customCategoriesProvider = FutureProvider<List<CustomCategory>>((
  ref,
) async {
  final rows = await Supabase.instance.client
      .from('custom_categories')
      .select('id, name')
      .order('name');
  return rows
      .map((row) => CustomCategory.fromJson(Map<String, dynamic>.from(row)))
      .toList(growable: false);
});

final recurringExpensesProvider = FutureProvider<List<RecurringExpense>>((
  ref,
) async {
  final rows = await Supabase.instance.client
      .from('recurring_expense_templates')
      .select()
      .order('next_run_at');
  return rows
      .map((row) => RecurringExpense.fromJson(Map<String, dynamic>.from(row)))
      .toList(growable: false);
});

final proFeaturesServiceProvider = Provider<ProFeaturesService>((ref) {
  return ProFeaturesService(Supabase.instance.client, ref);
});

class ProFeaturesService {
  ProFeaturesService(this._client, this._ref);
  final SupabaseClient _client;
  final Ref _ref;

  Future<void> createCustomCategory({required String name}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('custom_categories').insert({
      'user_id': userId,
      'name': name.trim(),
    });
    _ref.invalidate(customCategoriesProvider);
  }

  Future<void> deleteCustomCategory(String id) async {
    await _client.from('custom_categories').delete().eq('id', id);
    _ref.invalidate(customCategoriesProvider);
  }

  Future<void> updateCustomCategory({
    required String id,
    required String name,
  }) async {
    await _client
        .from('custom_categories')
        .update({
          'name': name.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    _ref.invalidate(customCategoriesProvider);
  }

  /// Creates the template and, when [nextRunAt] has already passed, its first
  /// expense in the same database transaction.
  ///
  /// This used to be a plain INSERT, which meant the first occurrence only
  /// appeared when the hourly job next ran -- so adding a recurring expense
  /// changed nothing the user could see, sometimes for an hour, sometimes
  /// until the following morning. The balance is derived from `transactions`,
  /// so no row meant no expense. `create_recurring_expense_v1` also recomputes
  /// the base amount server-side, which is why this no longer sends one.
  Future<void> createRecurringExpense({
    required String title,
    required String category,
    required double originalAmount,
    required String currencyCode,
    required double exchangeRate,
    required String rateSource,
    required DateTime rateLockedAt,
    required String frequency,
    required String timezone,
    required DateTime nextRunAt,
  }) async {
    if (_client.auth.currentUser?.id == null) {
      throw StateError('Not authenticated');
    }
    await _client.rpc(
      'create_recurring_expense_v1',
      params: {
        'p_title': title.trim(),
        'p_category': category.trim(),
        'p_original_amount': originalAmount,
        'p_currency_code': currencyCode,
        'p_exchange_rate': exchangeRate,
        'p_rate_source': rateSource,
        'p_rate_locked_at': rateLockedAt.toUtc().toIso8601String(),
        'p_frequency': frequency,
        'p_timezone': timezone,
        'p_next_run_at': nextRunAt.toUtc().toIso8601String(),
      },
    );
    _ref.invalidate(recurringExpensesProvider);
    // The balance and the transaction list both derive from this provider, so
    // an immediate first charge is invisible without it.
    _ref.invalidate(transactionsProvider);
  }

  Future<void> setRecurringActive(String id, bool active) async {
    await _client
        .from('recurring_expense_templates')
        .update({
          'is_active': active,
          if (active)
            'next_run_at': DateTime.now()
                .add(const Duration(days: 1))
                .toUtc()
                .toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    _ref.invalidate(recurringExpensesProvider);
  }

  Future<void> deleteRecurringExpense(String id) async {
    await _client.from('recurring_expense_templates').delete().eq('id', id);
    _ref.invalidate(recurringExpensesProvider);
  }

  Future<void> sendDebtReminder({
    required String expenseId,
    required String recipientId,
  }) async {
    await _client.functions.invoke(
      'send-debt-reminder',
      body: {'expense_id': expenseId, 'recipient_id': recipientId},
    );
  }
}
