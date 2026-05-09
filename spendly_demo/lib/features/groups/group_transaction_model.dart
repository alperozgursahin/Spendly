class GroupTransactionModel {
  final String? id;
  final String groupId;
  final String payerId;
  final double amount;
  final String description;
  final String splitType;
  final Map<String, dynamic> splitData;
  final DateTime? createdAt;

  GroupTransactionModel({
    this.id,
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.description,
    required this.splitType,
    required this.splitData,
    this.createdAt,
  });

  factory GroupTransactionModel.fromJson(Map<String, dynamic> json) {
    return GroupTransactionModel(
      id: json['id'] as String?,
      groupId: json['group_id'] as String,
      payerId: json['payer_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      splitType: json['split_type'] as String,
      splitData: json['split_data'] as Map<String, dynamic>,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'group_id': groupId,
      'payer_id': payerId,
      'amount': amount,
      'description': description,
      'split_type': splitType,
      'split_data': splitData,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}
