// lib/models/group_creation_request.dart

enum RequestStatus { pending, approved, rejected }

class GroupCreationRequest {
  final String id;
  final String domainId;
  final String applicantUserId;
  final String orgName;
  final String orgType;
  final int expectedCount;
  final String musterPoint;
  final String? leaderNotes;
  final RequestStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  // Optional joined relations from Supabase PostgREST queries
  final String? applicantName;
  final String? applicantPhone;

  GroupCreationRequest({
    required this.id,
    required this.domainId,
    required this.applicantUserId,
    required this.orgName,
    required this.orgType,
    required this.expectedCount,
    required this.musterPoint,
    this.leaderNotes,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.applicantName,
    this.applicantPhone,
  });

  factory GroupCreationRequest.fromJson(Map<String, dynamic> json) {
    String? applicantName;
    String? applicantPhone;
    if (json['users'] != null && json['users'] is Map) {
      final u = json['users'] as Map;
      applicantName = u['full_name'] as String?;
      applicantPhone = u['phone_number'] as String?;
    }

    return GroupCreationRequest(
      id: json['id'] as String,
      domainId: json['domain_id'] as String,
      applicantUserId: json['applicant_user_id'] as String,
      orgName: json['org_name'] as String,
      orgType: json['org_type'] as String,
      expectedCount: (json['expected_count'] as num?)?.toInt() ?? 20,
      musterPoint: json['muster_point'] as String,
      leaderNotes: json['leader_notes'] as String?,
      status: _parseStatus(json['status'] as String?),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      applicantName: applicantName,
      applicantPhone: applicantPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'applicant_user_id': applicantUserId,
      'org_name': orgName,
      'org_type': orgType,
      'expected_count': expectedCount,
      'muster_point': musterPoint,
      'leader_notes': leaderNotes,
      'status': _statusToString(status),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupCreationRequest copyWith({
    String? id,
    String? domainId,
    String? applicantUserId,
    String? orgName,
    String? orgType,
    int? expectedCount,
    String? musterPoint,
    String? leaderNotes,
    RequestStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    String? applicantName,
    String? applicantPhone,
  }) {
    return GroupCreationRequest(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      applicantUserId: applicantUserId ?? this.applicantUserId,
      orgName: orgName ?? this.orgName,
      orgType: orgType ?? this.orgType,
      expectedCount: expectedCount ?? this.expectedCount,
      musterPoint: musterPoint ?? this.musterPoint,
      leaderNotes: leaderNotes ?? this.leaderNotes,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      applicantName: applicantName ?? this.applicantName,
      applicantPhone: applicantPhone ?? this.applicantPhone,
    );
  }

  static RequestStatus _parseStatus(String? s) {
    switch (s?.toUpperCase()) {
      case 'APPROVED':
        return RequestStatus.approved;
      case 'REJECTED':
        return RequestStatus.rejected;
      case 'PENDING':
      default:
        return RequestStatus.pending;
    }
  }

  static String _statusToString(RequestStatus status) {
    switch (status) {
      case RequestStatus.approved:
        return 'APPROVED';
      case RequestStatus.rejected:
        return 'REJECTED';
      case RequestStatus.pending:
        return 'PENDING';
    }
  }
}
