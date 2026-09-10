class TransactionModel {
  TransactionModel({
    required this.userId,
    required this.originalAmount,
    required String currencyCode,
    required this.baseAmount,
    required String baseCurrencyCode,
    required this.exchangeRate,
    required String rateSource,
    required DateTime rateLockedAt,
    required this.category,
    required this.date,
    required this.type,
    this.id,
    this.groupId,
    this.createdAt,
  }) : currencyCode = _validateCurrencyCode(currencyCode),
       baseCurrencyCode = _validateCurrencyCode(baseCurrencyCode),
       rateSource = _requiredText(rateSource, 'rateSource'),
       rateLockedAt = rateLockedAt.toUtc() {
    if (userId.isEmpty || category.trim().isEmpty) {
      throw ArgumentError('Transaction user and category are required');
    }
    if (originalAmount < 0 || baseAmount < 0 || exchangeRate <= 0) {
      throw ArgumentError('Invalid transaction monetary values');
    }
    if (type != 'income' && type != 'expense') {
      throw ArgumentError.value(type, 'type', 'Must be income or expense');
    }
  }

  final String? id;
  final String userId;
  final String? groupId;
  final double originalAmount;
  final String currencyCode;
  final double baseAmount;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String rateSource;
  final DateTime rateLockedAt;
  final String category;
  final DateTime date;
  final String type;
  final DateTime? createdAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final legacyAmount = _requiredDouble(json['amount'], 'amount');
    return TransactionModel(
      id: json['id'] as String?,
      userId: _requiredText(json['user_id'], 'user_id'),
      groupId: json['group_id'] as String?,
      originalAmount: _optionalDouble(json['original_amount']) ?? legacyAmount,
      currencyCode: (json['currency_code'] as String?) ?? 'TRY',
      baseAmount: _optionalDouble(json['base_amount']) ?? legacyAmount,
      baseCurrencyCode: (json['base_currency_code'] as String?) ?? 'TRY',
      exchangeRate: _optionalDouble(json['exchange_rate']) ?? 1,
      rateSource: (json['rate_source'] as String?) ?? 'legacy_try_canonical',
      rateLockedAt:
          _optionalDateTime(json['rate_locked_at']) ??
          _optionalDateTime(json['created_at']) ??
          _requiredDate(json['date'], 'date'),
      category: _requiredText(json['category'], 'category'),
      date: _requiredDate(json['date'], 'date'),
      type: _requiredText(json['type'], 'type'),
      createdAt: _optionalDateTime(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'user_id': userId,
    if (groupId != null) 'group_id': groupId,

    // Retained until the legacy column is removed in the contract migration.
    'amount': baseAmount,
    'original_amount': originalAmount,
    'currency_code': currencyCode,
    'base_amount': baseAmount,
    'base_currency_code': baseCurrencyCode,
    'exchange_rate': exchangeRate,
    'rate_source': rateSource,
    'rate_locked_at': rateLockedAt.toUtc().toIso8601String(),
    'category': category,
    'date': _dateOnly(date),
    'type': type,
    if (createdAt != null) 'created_at': createdAt!.toUtc().toIso8601String(),
  };
}

String _requiredText(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

String _validateCurrencyCode(String value) {
  final code = value.trim().toUpperCase();
  if (!RegExp(r'^[A-Z0-9]{3,10}$').hasMatch(code)) {
    throw ArgumentError.value(value, 'currencyCode', 'Invalid currency code');
  }
  return code;
}

double _requiredDouble(Object? value, String field) {
  final result = _optionalDouble(value);
  if (result == null || !result.isFinite) {
    throw FormatException('$field must be a finite number');
  }
  return result;
}

double? _optionalDouble(Object? value) {
  return switch (value) {
    null => null,
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };
}

DateTime _requiredDate(Object? value, String field) {
  final parsed = value is DateTime
      ? value
      : value is String
      ? DateTime.tryParse(value)
      : null;
  if (parsed == null) throw FormatException('$field must be an ISO-8601 date');
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _optionalDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) return DateTime.tryParse(value)?.toUtc();
  return null;
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}
