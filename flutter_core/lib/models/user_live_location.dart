// lib/models/user_live_location.dart

class UserLiveLocation {
  final String id;
  final String domainId;
  final String userId;
  final String? activeGroupId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double heading;
  final DateTime updatedAt;

  // Optional joined relation
  final String? userName;

  UserLiveLocation({
    required this.id,
    required this.domainId,
    required this.userId,
    this.activeGroupId,
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0.0,
    this.heading = 0.0,
    required this.updatedAt,
    this.userName,
  });

  factory UserLiveLocation.fromJson(Map<String, dynamic> json) {
    String? userName;
    if (json['users'] != null && json['users'] is Map) {
      userName = json['users']['full_name'] as String?;
    } else if (json['user_name'] != null) {
      userName = json['user_name'] as String?;
    }

    return UserLiveLocation(
      id: json['id'] as String? ?? '',
      domainId: json['domain_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      activeGroupId: json['active_group_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      userName: userName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'user_id': userId,
      'active_group_id': activeGroupId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmh,
      'heading': heading,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserLiveLocation copyWith({
    String? id,
    String? domainId,
    String? userId,
    String? activeGroupId,
    double? latitude,
    double? longitude,
    double? speedKmh,
    double? heading,
    DateTime? updatedAt,
    String? userName,
  }) {
    return UserLiveLocation(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      userId: userId ?? this.userId,
      activeGroupId: activeGroupId ?? this.activeGroupId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmh: speedKmh ?? this.speedKmh,
      heading: heading ?? this.heading,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
    );
  }
}
