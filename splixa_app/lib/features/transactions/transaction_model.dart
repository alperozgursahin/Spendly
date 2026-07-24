class TransactionModel {
  final String? id;
  final String userId;
  final String? groupId;
  final double amount;
  final String category;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final DateTime? createdAt;

  TransactionModel({
    this.id,
    required this.userId,
    this.groupId,
    required this.amount,
    required this.category,
    required this.date,
    required this.type,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (groupId != null) 'group_id': groupId,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String().split('T')[0],
      'type': type,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
