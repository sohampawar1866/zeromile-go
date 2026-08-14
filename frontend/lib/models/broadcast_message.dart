// lib/models/broadcast_message.dart

enum SenderRole { superAdmin, groupLeader }
enum BroadcastTargetType { general, specificGroup }

class BroadcastMessage {
  final String id;
  final String domainId;
  final String senderId;
  final SenderRole senderRole;
  final BroadcastTargetType targetType;
  final String? targetGroupId;
  final String messageText;
  final DateTime createdAt;
  final String? senderName;

  BroadcastMessage({
    required this.id,
    required this.domainId,
    required this.senderId,
    required this.senderRole,
    required this.targetType,
    this.targetGroupId,
    required this.messageText,
    required this.createdAt,
    this.senderName,
  });

  factory BroadcastMessage.fromJson(Map<String, dynamic> json) {
    String? senderName;
    if (json['users'] != null && json['users'] is Map) {
      senderName = json['users']['full_name'] as String?;
    } else if (json['sender_name'] != null) {
      senderName = json['sender_name'] as String?;
    }

    return BroadcastMessage(
      id: json['id'] as String,
      domainId: json['domain_id'] as String,
      senderId: json['sender_id'] as String,
      senderRole: _parseRole(json['sender_role'] as String?),
      targetType: _parseTarget(json['target_type'] as String?),
      targetGroupId: json['target_group_id'] as String?,
      messageText: json['message_text'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      senderName: senderName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'sender_id': senderId,
      'sender_role': _roleToString(senderRole),
      'target_type': _targetToString(targetType),
      'target_group_id': targetGroupId,
      'message_text': messageText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BroadcastMessage copyWith({
    String? id,
    String? domainId,
    String? senderId,
    SenderRole? senderRole,
    BroadcastTargetType? targetType,
    String? targetGroupId,
    String? messageText,
    DateTime? createdAt,
    String? senderName,
  }) {
    return BroadcastMessage(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      targetType: targetType ?? this.targetType,
      targetGroupId: targetGroupId ?? this.targetGroupId,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
    );
  }

  static SenderRole _parseRole(String? s) {
    switch (s?.toUpperCase()) {
      case 'SUPERADMIN':
        return SenderRole.superAdmin;
      case 'GROUP_LEADER':
      default:
        return SenderRole.groupLeader;
    }
  }

  static String _roleToString(SenderRole role) {
    switch (role) {
      case SenderRole.superAdmin:
        return 'SUPERADMIN';
      case SenderRole.groupLeader:
        return 'GROUP_LEADER';
    }
  }

  static BroadcastTargetType _parseTarget(String? s) {
    switch (s?.toUpperCase()) {
      case 'SPECIFIC_GROUP':
        return BroadcastTargetType.specificGroup;
      case 'GENERAL':
      default:
        return BroadcastTargetType.general;
    }
  }

  static String _targetToString(BroadcastTargetType target) {
    switch (target) {
      case BroadcastTargetType.general:
        return 'GENERAL';
      case BroadcastTargetType.specificGroup:
        return 'SPECIFIC_GROUP';
    }
  }
}
