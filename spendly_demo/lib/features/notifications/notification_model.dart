class AppNotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String? groupId;
  final String? expenseId;
  final String type;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.groupId,
    required this.expenseId,
    required this.type,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      senderId: json['sender_id'] as String,
      groupId: json['group_id'] as String?,
      expenseId: json['expense_id'] as String?,
      type: (json['type'] as String?) ?? 'debt_request',
      message: (json['message'] as String?) ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
