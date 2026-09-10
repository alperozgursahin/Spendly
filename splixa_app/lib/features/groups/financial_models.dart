enum ExpenseSplitType { equal, percentage, exact, shares, itemized }

extension ExpenseSplitTypeCodec on ExpenseSplitType {
  String get databaseValue => name;

  static ExpenseSplitType parse(Object? value) {
    return switch (_requiredString(value, 'split_type')) {
      'equal' => ExpenseSplitType.equal,
      'percentage' => ExpenseSplitType.percentage,
      'exact' => ExpenseSplitType.exact,
      'shares' => ExpenseSplitType.shares,
      'itemized' => ExpenseSplitType.itemized,
      final value => throw FormatException('Unknown split_type: $value'),
    };
  }
}

enum ExpenseShareStatus {
  notOwed,
  pending,
  approved,
  paymentPending,
  settled,
  rejected,
}

extension ExpenseShareStatusCodec on ExpenseShareStatus {
  String get databaseValue => switch (this) {
    ExpenseShareStatus.notOwed => 'not_owed',
    ExpenseShareStatus.pending => 'pending',
    ExpenseShareStatus.approved => 'approved',
    ExpenseShareStatus.paymentPending => 'payment_pending',
    ExpenseShareStatus.settled => 'settled',
    ExpenseShareStatus.rejected => 'rejected',
  };

  static ExpenseShareStatus parse(Object? value) {
    return switch (_requiredString(value, 'status')) {
      'not_owed' => ExpenseShareStatus.notOwed,
      'pending' => ExpenseShareStatus.pending,
      'approved' => ExpenseShareStatus.approved,
      'payment_pending' => ExpenseShareStatus.paymentPending,
      'settled' => ExpenseShareStatus.settled,
      'rejected' => ExpenseShareStatus.rejected,
      final value => throw FormatException(
        'Unknown expense share status: $value',
      ),
    };
  }
}

enum SettlementStatus { proposed, paymentPending, settled, rejected, cancelled }

enum ExpenseBucket { pendingApproval, active, archived }

extension SettlementStatusCodec on SettlementStatus {
  String get databaseValue => switch (this) {
    SettlementStatus.proposed => 'proposed',
    SettlementStatus.paymentPending => 'payment_pending',
    SettlementStatus.settled => 'settled',
    SettlementStatus.rejected => 'rejected',
    SettlementStatus.cancelled => 'cancelled',
  };

  static SettlementStatus parse(Object? value) {
    return switch (_requiredString(value, 'status')) {
      'proposed' => SettlementStatus.proposed,
      'payment_pending' => SettlementStatus.paymentPending,
      'settled' => SettlementStatus.settled,
      'rejected' => SettlementStatus.rejected,
      'cancelled' => SettlementStatus.cancelled,
      final value => throw FormatException('Unknown settlement status: $value'),
    };
  }
}

/// A normalized group expense. PostgreSQL remains the source of truth for all
/// monetary arithmetic; Dart values are transport/display values only.
class Expense {
  const Expense({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.payerId,
    required this.description,
    required this.expenseDate,
    required this.splitType,
    required this.originalAmount,
    required this.currencyCode,
    required this.baseAmount,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.rateSource,
    required this.rateLockedAt,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.category,
    this.notes,
    this.archivedAt,
  });

  final String id;
  final String groupId;
  final String createdBy;
  final String payerId;
  final String description;
  final String? category;
  final String? notes;
  final DateTime expenseDate;
  final ExpenseSplitType splitType;
  final double originalAmount;
  final String currencyCode;
  final double baseAmount;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String rateSource;
  final DateTime rateLockedAt;
  final String source;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  factory Expense.fromJson(Map<String, dynamic> json) {
    final currencyCode = _currencyCode(json['currency_code'], 'currency_code');
    final baseCurrencyCode = _currencyCode(
      json['base_currency_code'],
      'base_currency_code',
    );
    final originalAmount = _requiredDouble(
      json['original_amount'],
      'original_amount',
    );
    final baseAmount = _requiredDouble(json['base_amount'], 'base_amount');
    final exchangeRate = _requiredDouble(
      json['exchange_rate'],
      'exchange_rate',
    );

    if (originalAmount <= 0 || baseAmount <= 0 || exchangeRate <= 0) {
      throw const FormatException('Expense monetary values must be positive');
    }

    return Expense(
      id: _requiredString(json['id'], 'id'),
      groupId: _requiredString(json['group_id'], 'group_id'),
      createdBy: _requiredString(json['created_by'], 'created_by'),
      payerId: _requiredString(json['payer_id'], 'payer_id'),
      description: _requiredString(json['description'], 'description'),
      category: _optionalString(json['category']),
      notes: _optionalString(json['notes']),
      expenseDate: _requiredDate(json['expense_date'], 'expense_date'),
      splitType: ExpenseSplitTypeCodec.parse(json['split_type']),
      originalAmount: originalAmount,
      currencyCode: currencyCode,
      baseAmount: baseAmount,
      baseCurrencyCode: baseCurrencyCode,
      exchangeRate: exchangeRate,
      rateSource: _requiredString(json['rate_source'], 'rate_source'),
      rateLockedAt: _requiredDateTime(json['rate_locked_at'], 'rate_locked_at'),
      source: _requiredString(json['source'], 'source'),
      archivedAt: _optionalDateTime(json['archived_at'], 'archived_at'),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
      version: _requiredInt(json['version'], 'version'),
    );
  }
}

class ExpenseShare {
  const ExpenseShare({
    required this.expenseId,
    required this.participantId,
    required this.originalShareAmount,
    required this.baseShareAmount,
    required this.status,
    required this.statusUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.sharePercentage,
    this.shareUnits,
  });

  final String expenseId;
  final String participantId;
  final double originalShareAmount;
  final double baseShareAmount;
  final double? sharePercentage;
  final double? shareUnits;
  final ExpenseShareStatus status;
  final DateTime statusUpdatedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get affectsBalance => switch (status) {
    ExpenseShareStatus.approved ||
    ExpenseShareStatus.paymentPending ||
    ExpenseShareStatus.settled => true,
    _ => false,
  };

  factory ExpenseShare.fromJson(Map<String, dynamic> json) {
    final originalAmount = _requiredDouble(
      json['original_share_amount'],
      'original_share_amount',
    );
    final baseAmount = _requiredDouble(
      json['base_share_amount'],
      'base_share_amount',
    );
    if (originalAmount < 0 || baseAmount < 0) {
      throw const FormatException('Expense share amounts cannot be negative');
    }

    return ExpenseShare(
      expenseId: _requiredString(json['expense_id'], 'expense_id'),
      participantId: _requiredString(json['participant_id'], 'participant_id'),
      originalShareAmount: originalAmount,
      baseShareAmount: baseAmount,
      sharePercentage: _optionalDouble(
        json['share_percentage'],
        'share_percentage',
      ),
      shareUnits: _optionalDouble(json['share_units'], 'share_units'),
      status: ExpenseShareStatusCodec.parse(json['status']),
      statusUpdatedAt: _requiredDateTime(
        json['status_updated_at'],
        'status_updated_at',
      ),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
      version: _requiredInt(json['version'], 'version'),
    );
  }
}

class Settlement {
  const Settlement({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.paidBy,
    required this.receivedBy,
    required this.originalAmount,
    required this.currencyCode,
    required this.baseAmount,
    required this.baseCurrencyCode,
    required this.exchangeRate,
    required this.rateSource,
    required this.rateLockedAt,
    required this.status,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.expenseId,
    this.notes,
    this.paidAt,
    this.confirmedAt,
  });

  final String id;
  final String groupId;
  final String? expenseId;
  final String createdBy;
  final String paidBy;
  final String receivedBy;
  final double originalAmount;
  final String currencyCode;
  final double baseAmount;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String rateSource;
  final DateTime rateLockedAt;
  final SettlementStatus status;
  final String? notes;
  final DateTime? paidAt;
  final DateTime? confirmedAt;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  factory Settlement.fromJson(Map<String, dynamic> json) {
    final originalAmount = _requiredDouble(
      json['original_amount'],
      'original_amount',
    );
    final baseAmount = _requiredDouble(json['base_amount'], 'base_amount');
    final exchangeRate = _requiredDouble(
      json['exchange_rate'],
      'exchange_rate',
    );
    if (originalAmount <= 0 || baseAmount <= 0 || exchangeRate <= 0) {
      throw const FormatException(
        'Settlement monetary values must be positive',
      );
    }

    return Settlement(
      id: _requiredString(json['id'], 'id'),
      groupId: _requiredString(json['group_id'], 'group_id'),
      expenseId: _optionalString(json['expense_id']),
      createdBy: _requiredString(json['created_by'], 'created_by'),
      paidBy: _requiredString(json['paid_by'], 'paid_by'),
      receivedBy: _requiredString(json['received_by'], 'received_by'),
      originalAmount: originalAmount,
      currencyCode: _currencyCode(json['currency_code'], 'currency_code'),
      baseAmount: baseAmount,
      baseCurrencyCode: _currencyCode(
        json['base_currency_code'],
        'base_currency_code',
      ),
      exchangeRate: exchangeRate,
      rateSource: _requiredString(json['rate_source'], 'rate_source'),
      rateLockedAt: _requiredDateTime(json['rate_locked_at'], 'rate_locked_at'),
      status: SettlementStatusCodec.parse(json['status']),
      notes: _optionalString(json['notes']),
      paidAt: _optionalDateTime(json['paid_at'], 'paid_at'),
      confirmedAt: _optionalDateTime(json['confirmed_at'], 'confirmed_at'),
      source: _requiredString(json['source'], 'source'),
      createdAt: _requiredDateTime(json['created_at'], 'created_at'),
      updatedAt: _requiredDateTime(json['updated_at'], 'updated_at'),
      version: _requiredInt(json['version'], 'version'),
    );
  }
}

class GroupBalance {
  const GroupBalance({
    required this.groupId,
    required this.userId,
    required this.currencyCode,
    required this.balance,
  });

  final String groupId;
  final String userId;
  final String currencyCode;

  /// Positive means this user is owed money; negative means this user owes.
  final double balance;

  factory GroupBalance.fromJson(Map<String, dynamic> json) {
    return GroupBalance(
      groupId: _requiredString(json['group_id'], 'group_id'),
      userId: _requiredString(json['user_id'], 'user_id'),
      currencyCode: _currencyCode(json['currency_code'], 'currency_code'),
      balance: _requiredDouble(json['balance'], 'balance'),
    );
  }
}

class ExpenseWithShares {
  const ExpenseWithShares({required this.expense, required this.shares});

  final Expense expense;
  final List<ExpenseShare> shares;

  ExpenseBucket get bucket {
    if (expense.archivedAt != null) return ExpenseBucket.archived;
    return hasPendingDecision
        ? ExpenseBucket.pendingApproval
        : ExpenseBucket.active;
  }

  ExpenseShare? shareFor(String participantId) {
    for (final share in shares) {
      if (share.participantId == participantId) return share;
    }
    return null;
  }

  bool get hasPendingDecision => shares.any(
    (share) =>
        share.participantId != expense.payerId &&
        (share.status == ExpenseShareStatus.pending ||
            share.status == ExpenseShareStatus.rejected),
  );

  bool get allNonPayerSharesSettled => shares
      .where((share) => share.participantId != expense.payerId)
      .every((share) => share.status == ExpenseShareStatus.settled);
}

/// Input for the atomic create_expense_v1 RPC. The server independently
/// validates membership, totals, currencies, rate math, and initial statuses.
class ExpenseDraft {
  ExpenseDraft({
    required this.groupId,
    required this.payerId,
    required this.description,
    required this.expenseDate,
    required this.splitType,
    required this.originalAmount,
    required String currencyCode,
    required this.baseAmount,
    required String baseCurrencyCode,
    required this.exchangeRate,
    required this.rateSource,
    required this.rateLockedAt,
    required List<ExpenseShareDraft> shares,
    this.category,
    this.notes,
  }) : currencyCode = _validateCurrencyInput(currencyCode),
       baseCurrencyCode = _validateCurrencyInput(baseCurrencyCode),
       shares = List.unmodifiable(shares) {
    if (groupId.isEmpty || payerId.isEmpty || description.trim().isEmpty) {
      throw ArgumentError('Expense group, payer, and description are required');
    }
    if (originalAmount <= 0 || baseAmount <= 0 || exchangeRate <= 0) {
      throw ArgumentError('Expense monetary values must be positive');
    }
    if (shares.isEmpty) {
      throw ArgumentError('An expense requires at least one share');
    }
  }

  final String groupId;
  final String payerId;
  final String description;
  final String? category;
  final String? notes;
  final DateTime expenseDate;
  final ExpenseSplitType splitType;
  final double originalAmount;
  final String currencyCode;
  final double baseAmount;
  final String baseCurrencyCode;
  final double exchangeRate;
  final String rateSource;
  final DateTime rateLockedAt;
  final List<ExpenseShareDraft> shares;

  Map<String, dynamic> toRpcParameters() => {
    'p_group_id': groupId,
    'p_payer_id': payerId,
    'p_description': description.trim(),
    'p_category': category?.trim(),
    'p_notes': notes?.trim(),
    'p_expense_date': _dateOnly(expenseDate),
    'p_split_type': splitType.databaseValue,
    'p_original_amount': originalAmount,
    'p_currency_code': currencyCode,
    'p_base_amount': baseAmount,
    'p_base_currency_code': baseCurrencyCode,
    'p_exchange_rate': exchangeRate,
    'p_rate_source': rateSource.trim(),
    'p_rate_locked_at': rateLockedAt.toUtc().toIso8601String(),
    'p_shares': shares.map((share) => share.toJson()).toList(),
  };
}

class ExpenseShareDraft {
  const ExpenseShareDraft({
    required this.participantId,
    required this.originalShareAmount,
    required this.baseShareAmount,
    this.sharePercentage,
    this.shareUnits,
  });

  final String participantId;
  final double originalShareAmount;
  final double baseShareAmount;
  final double? sharePercentage;
  final double? shareUnits;

  Map<String, dynamic> toJson() {
    if (participantId.isEmpty ||
        originalShareAmount < 0 ||
        baseShareAmount < 0) {
      throw ArgumentError('Invalid expense share');
    }

    return {
      'participant_id': participantId,
      'original_share_amount': originalShareAmount,
      'base_share_amount': baseShareAmount,
      if (sharePercentage != null) 'share_percentage': sharePercentage,
      if (shareUnits != null) 'share_units': shareUnits,
    };
  }
}

String _requiredString(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  if (value is! String) throw const FormatException('Expected a string');
  return value;
}

String _currencyCode(Object? value, String field) {
  final code = _requiredString(value, field).toUpperCase();
  if (!RegExp(r'^[A-Z0-9]{3,10}$').hasMatch(code)) {
    throw FormatException('Invalid $field: $code');
  }
  return code;
}

String _validateCurrencyInput(String value) {
  final code = value.trim().toUpperCase();
  if (!RegExp(r'^[A-Z0-9]{3,10}$').hasMatch(code)) {
    throw ArgumentError.value(value, 'currencyCode', 'Invalid currency code');
  }
  return code;
}

double _requiredDouble(Object? value, String field) {
  final parsed = switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text),
    _ => null,
  };
  if (parsed == null || !parsed.isFinite) {
    throw FormatException('$field must be a finite number');
  }
  return parsed;
}

double? _optionalDouble(Object? value, String field) {
  if (value == null) return null;
  return _requiredDouble(value, field);
}

int _requiredInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num && value == value.roundToDouble()) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('$field must be an integer');
}

DateTime _requiredDateTime(Object? value, String field) {
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toUtc();
  }
  throw FormatException('$field must be an ISO-8601 timestamp');
}

DateTime? _optionalDateTime(Object? value, String field) {
  if (value == null) return null;
  return _requiredDateTime(value, field);
}

DateTime _requiredDate(Object? value, String field) {
  if (value is DateTime) {
    return DateTime(value.year, value.month, value.day);
  }
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return DateTime(parsed.year, parsed.month, parsed.day);
  }
  throw FormatException('$field must be an ISO-8601 date');
}

String _dateOnly(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
