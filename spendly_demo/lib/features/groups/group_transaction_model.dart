enum DebtApprovalStatus { pending, approved, paymentPending, settled, rejected }

bool isDebtCountedStatus(DebtApprovalStatus status) {
  return status == DebtApprovalStatus.approved ||
      status == DebtApprovalStatus.paymentPending;
}

DebtApprovalStatus participantApprovalStatus(
  Map<String, dynamic> splitData,
  String participantId,
  String payerId,
) {
  // Payer has no debt to acknowledge or settle.
  if (participantId == payerId) return DebtApprovalStatus.approved;

  final rawValue = splitData[participantId];

  if (rawValue is Map) {
    switch (rawValue['status'] as String?) {
      case 'pending':
        return DebtApprovalStatus.pending;
      case 'approved':
        return DebtApprovalStatus.approved;
      case 'payment_pending':
        return DebtApprovalStatus.paymentPending;
      case 'settled':
        return DebtApprovalStatus.settled;
      case 'rejected':
        return DebtApprovalStatus.rejected;
    }
  }

  // Old rows without a status remain financially active for compatibility.
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
  final String status;
  final DateTime? createdAt;

  GroupTransactionModel({
    this.id,
    required this.groupId,
    required this.payerId,
    required this.amount,
    required this.description,
    required this.splitType,
    required this.splitData,
    this.status = 'pending',
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
      status: (json['status'] as String?) ?? 'pending',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
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
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
