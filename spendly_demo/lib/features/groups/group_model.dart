class GroupModel {
  final String? id;
  final String name;
  final String createdBy;
  final DateTime? createdAt;

  GroupModel({
    this.id,
    required this.name,
    required this.createdBy,
    this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
}

class GroupMemberModel {
  final String groupId;
  final String userId;
  final String? username;
  final String? avatarUrl;

  GroupMemberModel({
    required this.groupId,
    required this.userId,
    this.username,
    this.avatarUrl,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      username: json['profiles']?['username'] as String?,
      avatarUrl: json['profiles']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'group_id': groupId, 'user_id': userId};
  }
}
