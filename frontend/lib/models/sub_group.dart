// lib/models/sub_group.dart

enum GroupApprovalStatus { pending, approved, rejected, suspended }

class SubGroup {
  final String id;
  final String domainId;
  final String name;
  final bool isGeneral;
  final String orgType;
  final String? leaderId;
  final String? musterPoint;
  final GroupApprovalStatus approvalStatus;
  final DateTime createdAt;

  SubGroup({
    required this.id,
    required this.domainId,
    required this.name,
    required this.isGeneral,
    required this.orgType,
    this.leaderId,
    this.musterPoint,
    required this.approvalStatus,
    required this.createdAt,
  });

  factory SubGroup.fromJson(Map<String, dynamic> json) {
    return SubGroup(
      id: json['id'] as String,
      domainId: json['domain_id'] as String,
      name: json['name'] as String,
      isGeneral: json['is_general'] as bool? ?? false,
      orgType: json['org_type'] as String? ?? 'GENERAL',
      leaderId: json['leader_id'] as String?,
      musterPoint: json['muster_point'] as String?,
      approvalStatus: _parseApprovalStatus(json['approval_status'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'name': name,
      'is_general': isGeneral,
      'org_type': orgType,
      'leader_id': leaderId,
      'muster_point': musterPoint,
      'approval_status': _statusToString(approvalStatus),
      'created_at': createdAt.toIso8601String(),
    };
  }

  SubGroup copyWith({
    String? id,
    String? domainId,
    String? name,
    bool? isGeneral,
    String? orgType,
    String? leaderId,
    String? musterPoint,
    GroupApprovalStatus? approvalStatus,
    DateTime? createdAt,
  }) {
    return SubGroup(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      name: name ?? this.name,
      isGeneral: isGeneral ?? this.isGeneral,
      orgType: orgType ?? this.orgType,
      leaderId: leaderId ?? this.leaderId,
      musterPoint: musterPoint ?? this.musterPoint,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static GroupApprovalStatus _parseApprovalStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'PENDING':
        return GroupApprovalStatus.pending;
      case 'REJECTED':
        return GroupApprovalStatus.rejected;
      case 'SUSPENDED':
        return GroupApprovalStatus.suspended;
      case 'APPROVED':
      default:
        return GroupApprovalStatus.approved;
    }
  }

  static String _statusToString(GroupApprovalStatus status) {
    switch (status) {
      case GroupApprovalStatus.pending:
        return 'PENDING';
      case GroupApprovalStatus.approved:
        return 'APPROVED';
      case GroupApprovalStatus.rejected:
        return 'REJECTED';
      case GroupApprovalStatus.suspended:
        return 'SUSPENDED';
    }
  }
}
