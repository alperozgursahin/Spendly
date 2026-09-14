import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomCategory {
  const CustomCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
  });
  final String id;
  final String name;
  final String emoji;
  final int colorValue;

  factory CustomCategory.fromJson(Map<String, dynamic> json) => CustomCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    emoji: json['emoji'] as String,
    colorValue: (json['color_value'] as num).toInt(),
  );
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
      .select('id, name, emoji, color_value')
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

  Future<void> createCustomCategory({
    required String name,
    required String emoji,
    required int colorValue,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('custom_categories').insert({
      'user_id': userId,
      'name': name.trim(),
      'emoji': emoji.trim(),
      'color_value': colorValue,
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
    required String emoji,
    required int colorValue,
  }) async {
    await _client
        .from('custom_categories')
        .update({
          'name': name.trim(),
          'emoji': emoji.trim(),
          'color_value': colorValue,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
    _ref.invalidate(customCategoriesProvider);
  }

  Future<void> createRecurringExpense({
    required String title,
    required String category,
    required double originalAmount,
    required String currencyCode,
    required double baseAmount,
    required double exchangeRate,
    required String rateSource,
    required DateTime rateLockedAt,
    required String frequency,
    required String timezone,
    required DateTime nextRunAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');
    await _client.from('recurring_expense_templates').insert({
      'user_id': userId,
      'title': title.trim(),
      'category': category.trim(),
      'original_amount': originalAmount,
      'currency_code': currencyCode,
      'base_amount': baseAmount,
      'base_currency_code': 'TRY',
      'exchange_rate': exchangeRate,
      'rate_source': rateSource,
      'rate_locked_at': rateLockedAt.toUtc().toIso8601String(),
      'frequency': frequency,
      'interval_count': 1,
      'timezone': timezone,
      'next_run_at': nextRunAt.toUtc().toIso8601String(),
    });
    _ref.invalidate(recurringExpensesProvider);
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
