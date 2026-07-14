enum DebtApprovalStatus { pending, approved, rejected }

// Reads the approval status of one participant's share of a group
// transaction. The payer's own share never needs approval. A missing
// `status` key means the row predates this feature — treat it as approved
// so existing history doesn't suddenly appear "pending" for everyone.
DebtApprovalStatus participantApprovalStatus(
  Map<String, dynamic> splitData,
  String participantId,
  String payerId,
) {
  if (participantId == payerId) return DebtApprovalStatus.approved;

  final rawValue = splitData[participantId];
  if (rawValue is Map) {
    switch (rawValue['status'] as String?) {
      case 'pending':
        return DebtApprovalStatus.pending;
      case 'rejected':
        return DebtApprovalStatus.rejected;
    }
  }

  return DebtApprovalStatus.approved;
}

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
      splitData: Map<String, dynamic>.from(json['split_data'] as Map),
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
