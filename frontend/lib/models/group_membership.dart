// lib/models/group_membership.dart

enum ParticipationStatus { notCheckedIn, checkedIn, inTransit, completed, droppedOut }

class GroupMembership {
  final String id;
  final String domainId;
  final String groupId;
  final String userId;
  final bool isActive;
  final bool isLeader;
  final ParticipationStatus participationStatus;
  final DateTime? checkinTime;
  final DateTime? completionTime;
  final DateTime joinedAt;

  // Optional joined relations from Supabase PostgREST queries
  final String? groupName;
  final String? userFullName;
  final String? userPhoneNumber;
  final String? userAvatarUrl;
  final String? emergencyContact;

  GroupMembership({
    required this.id,
    required this.domainId,
    required this.groupId,
    required this.userId,
    required this.isActive,
    required this.isLeader,
    required this.participationStatus,
    this.checkinTime,
    this.completionTime,
    required this.joinedAt,
    this.groupName,
    this.userFullName,
    this.userPhoneNumber,
    this.userAvatarUrl,
    this.emergencyContact,
  });

  factory GroupMembership.fromJson(Map<String, dynamic> json) {
    String? groupName;
    if (json['sub_groups'] != null && json['sub_groups'] is Map) {
      groupName = json['sub_groups']['name'] as String?;
    }

    String? userFullName;
    String? userPhoneNumber;
    String? userAvatarUrl;
    String? emergencyContact;
    if (json['users'] != null && json['users'] is Map) {
      final u = json['users'] as Map;
      userFullName = u['full_name'] as String?;
      userPhoneNumber = u['phone_number'] as String?;
      userAvatarUrl = u['avatar_url'] as String?;
      emergencyContact = u['emergency_contact'] as String?;
    }

    return GroupMembership(
      id: json['id'] as String,
      domainId: json['domain_id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      isActive: json['is_active'] as bool? ?? false,
      isLeader: json['is_leader'] as bool? ?? false,
      participationStatus: _parseParticipationStatus(json['participation_status'] as String?),
      checkinTime: json['checkin_time'] != null ? DateTime.parse(json['checkin_time'].toString()) : null,
      completionTime: json['completion_time'] != null ? DateTime.parse(json['completion_time'].toString()) : null,
      joinedAt: json['joined_at'] != null ? DateTime.parse(json['joined_at'].toString()) : DateTime.now(),
      groupName: groupName,
      userFullName: userFullName,
      userPhoneNumber: userPhoneNumber,
      userAvatarUrl: userAvatarUrl,
      emergencyContact: emergencyContact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'group_id': groupId,
      'user_id': userId,
      'is_active': isActive,
      'is_leader': isLeader,
      'participation_status': _statusToString(participationStatus),
      'checkin_time': checkinTime?.toIso8601String(),
      'completion_time': completionTime?.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  GroupMembership copyWith({
    String? id,
    String? domainId,
    String? groupId,
    String? userId,
    bool? isActive,
    bool? isLeader,
    ParticipationStatus? participationStatus,
    DateTime? checkinTime,
    DateTime? completionTime,
    DateTime? joinedAt,
    String? groupName,
    String? userFullName,
    String? userPhoneNumber,
    String? userAvatarUrl,
    String? emergencyContact,
  }) {
    return GroupMembership(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      isLeader: isLeader ?? this.isLeader,
      participationStatus: participationStatus ?? this.participationStatus,
      checkinTime: checkinTime ?? this.checkinTime,
      completionTime: completionTime ?? this.completionTime,
      joinedAt: joinedAt ?? this.joinedAt,
      groupName: groupName ?? this.groupName,
      userFullName: userFullName ?? this.userFullName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  static ParticipationStatus _parseParticipationStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'CHECKED_IN':
        return ParticipationStatus.checkedIn;
      case 'IN_TRANSIT':
        return ParticipationStatus.inTransit;
      case 'COMPLETED':
        return ParticipationStatus.completed;
      case 'DROPPED_OUT':
        return ParticipationStatus.droppedOut;
      case 'NOT_CHECKED_IN':
      default:
        return ParticipationStatus.notCheckedIn;
    }
  }

  static String _statusToString(ParticipationStatus s) {
    switch (s) {
      case ParticipationStatus.checkedIn:
        return 'CHECKED_IN';
      case ParticipationStatus.inTransit:
        return 'IN_TRANSIT';
      case ParticipationStatus.completed:
        return 'COMPLETED';
      case ParticipationStatus.droppedOut:
        return 'DROPPED_OUT';
      case ParticipationStatus.notCheckedIn:
        return 'NOT_CHECKED_IN';
    }
  }
}
