class AppNotificationModel {
  final String id;
  final String recipientId;
  final String actorId;
  final String groupId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.groupId,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      actorId: json['actor_id'] as String,
      groupId: json['group_id'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}