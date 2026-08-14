// lib/models/domain_superadmin.dart

class DomainSuperAdmin {
  final String id;
  final String domainId;
  final String userId;
  final String createdByDev;
  final DateTime assignedAt;

  // Optional joined relation from Supabase PostgREST queries
  final String? userFullName;
  final String? userPhoneNumber;
  final String? userAvatarUrl;

  DomainSuperAdmin({
    required this.id,
    required this.domainId,
    required this.userId,
    required this.createdByDev,
    required this.assignedAt,
    this.userFullName,
    this.userPhoneNumber,
    this.userAvatarUrl,
  });

  factory DomainSuperAdmin.fromJson(Map<String, dynamic> json) {
    String? userFullName;
    String? userPhoneNumber;
    String? userAvatarUrl;

    if (json['users'] != null && json['users'] is Map) {
      final u = json['users'] as Map;
      userFullName = u['full_name'] as String?;
      userPhoneNumber = u['phone_number'] as String?;
      userAvatarUrl = u['avatar_url'] as String?;
    }

    return DomainSuperAdmin(
      id: json['id'] as String,
      domainId: json['domain_id'] as String,
      userId: json['user_id'] as String,
      createdByDev: json['created_by_dev'] as String? ?? 'developer',
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'].toString())
          : DateTime.now(),
      userFullName: userFullName,
      userPhoneNumber: userPhoneNumber,
      userAvatarUrl: userAvatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'user_id': userId,
      'created_by_dev': createdByDev,
      'assigned_at': assignedAt.toIso8601String(),
    };
  }

  DomainSuperAdmin copyWith({
    String? id,
    String? domainId,
    String? userId,
    String? createdByDev,
    DateTime? assignedAt,
    String? userFullName,
    String? userPhoneNumber,
    String? userAvatarUrl,
  }) {
    return DomainSuperAdmin(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      userId: userId ?? this.userId,
      createdByDev: createdByDev ?? this.createdByDev,
      assignedAt: assignedAt ?? this.assignedAt,
      userFullName: userFullName ?? this.userFullName,
      userPhoneNumber: userPhoneNumber ?? this.userPhoneNumber,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}
