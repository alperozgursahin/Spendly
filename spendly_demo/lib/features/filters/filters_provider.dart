import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionFilters {
  final DateTime? start;
  final DateTime? end;
  final String groupId;
  final String category;
  final String type;
  final String personId;

  const TransactionFilters({
    this.start,
    this.end,
    this.groupId = '',
    this.category = '',
    this.type = '',
    this.personId = '',
  });

  TransactionFilters copyWith({
    DateTime? start,
    DateTime? end,
    String? groupId,
    String? category,
    String? type,
    String? personId,
  }) {
    return TransactionFilters(
      start: start ?? this.start,
      end: end ?? this.end,
      groupId: groupId ?? this.groupId,
      category: category ?? this.category,
      type: type ?? this.type,
      personId: personId ?? this.personId,
    );
  }
}

class TransactionFiltersNotifier extends StateNotifier<TransactionFilters> {
  TransactionFiltersNotifier() : super(const TransactionFilters());

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(start: start, end: end);
  }

  void setGroup(String? groupId) {
    state = state.copyWith(groupId: groupId ?? '');
  }

  void setCategory(String? category) {
    state = state.copyWith(category: category ?? '');
  }

  void setType(String? type) {
    state = state.copyWith(type: type ?? '');
  }

  void setPerson(String? personId) {
    state = state.copyWith(personId: personId ?? '');
  }

  void clear() {
    state = const TransactionFilters();
  }
}

final transactionFilterProvider = StateNotifierProvider<TransactionFiltersNotifier, TransactionFilters>((ref) {
  return TransactionFiltersNotifier();
});
