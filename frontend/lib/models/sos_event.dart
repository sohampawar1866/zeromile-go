// lib/models/sos_event.dart

enum EmergencyType { medical, breakdown, threat, lost, other }
enum SosStatus { triggered, forwardedToAdmin, resolved }

class SosEvent {
  final String id;
  final String domainId;
  final String senderUserId;
  final String? activeSubGroupId;
  final EmergencyType emergencyType;
  final double latitude;
  final double longitude;
  final SosStatus status;
  final String? forwardedByLeaderId;
  final String? leaderNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;

  // Optional joined relations from Supabase PostgREST queries
  final String? senderName;
  final String? senderPhone;
  final String? groupName;

  SosEvent({
    required this.id,
    required this.domainId,
    required this.senderUserId,
    this.activeSubGroupId,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.forwardedByLeaderId,
    this.leaderNotes,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    this.senderName,
    this.senderPhone,
    this.groupName,
  });

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    String? senderName;
    String? senderPhone;
    if (json['users'] != null && json['users'] is Map) {
      final u = json['users'] as Map;
      senderName = u['full_name'] as String?;
      senderPhone = u['phone_number'] as String?;
    } else {
      senderName = json['sender_name'] as String?;
      senderPhone = json['sender_phone'] as String?;
    }

    String? groupName;
    if (json['sub_groups'] != null && json['sub_groups'] is Map) {
      groupName = json['sub_groups']['name'] as String?;
    } else {
      groupName = json['group_name'] as String?;
    }

    return SosEvent(
      id: json['id'] as String? ?? '',
      domainId: json['domain_id'] as String? ?? '',
      senderUserId: json['sender_user_id'] as String? ?? '',
      activeSubGroupId: json['active_sub_group_id'] as String?,
      emergencyType: _parseEmergencyType(json['emergency_type'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status'] as String?),
      forwardedByLeaderId: json['forwarded_by_leader_id'] as String?,
      leaderNotes: json['leader_notes'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      senderName: senderName,
      senderPhone: senderPhone,
      groupName: groupName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'sender_user_id': senderUserId,
      'active_sub_group_id': activeSubGroupId,
      'emergency_type': _emergencyTypeToString(emergencyType),
      'latitude': latitude,
      'longitude': longitude,
      'status': _statusToString(status),
      'forwarded_by_leader_id': forwardedByLeaderId,
      'leader_notes': leaderNotes,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  SosEvent copyWith({
    String? id,
    String? domainId,
    String? senderUserId,
    String? activeSubGroupId,
    EmergencyType? emergencyType,
    double? latitude,
    double? longitude,
    SosStatus? status,
    String? forwardedByLeaderId,
    String? leaderNotes,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    String? senderName,
    String? senderPhone,
    String? groupName,
  }) {
    return SosEvent(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      senderUserId: senderUserId ?? this.senderUserId,
      activeSubGroupId: activeSubGroupId ?? this.activeSubGroupId,
      emergencyType: emergencyType ?? this.emergencyType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      forwardedByLeaderId: forwardedByLeaderId ?? this.forwardedByLeaderId,
      leaderNotes: leaderNotes ?? this.leaderNotes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      groupName: groupName ?? this.groupName,
    );
  }

  static EmergencyType _parseEmergencyType(String? s) {
    switch (s?.toUpperCase()) {
      case 'BREAKDOWN':
        return EmergencyType.breakdown;
      case 'THREAT':
        return EmergencyType.threat;
      case 'LOST':
        return EmergencyType.lost;
      case 'OTHER':
        return EmergencyType.other;
      case 'MEDICAL':
      default:
        return EmergencyType.medical;
    }
  }

  static String _emergencyTypeToString(EmergencyType type) {
    switch (type) {
      case EmergencyType.medical:
        return 'MEDICAL';
      case EmergencyType.breakdown:
        return 'BREAKDOWN';
      case EmergencyType.threat:
        return 'THREAT';
      case EmergencyType.lost:
        return 'LOST';
      case EmergencyType.other:
        return 'OTHER';
    }
  }

  static SosStatus _parseStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'FORWARDED_TO_ADMIN':
        return SosStatus.forwardedToAdmin;
      case 'RESOLVED':
        return SosStatus.resolved;
      case 'TRIGGERED':
      default:
        return SosStatus.triggered;
    }
  }

  static String _statusToString(SosStatus s) {
    switch (s) {
      case SosStatus.forwardedToAdmin:
        return 'FORWARDED_TO_ADMIN';
      case SosStatus.resolved:
        return 'RESOLVED';
      case SosStatus.triggered:
        return 'TRIGGERED';
    }
  }
}
