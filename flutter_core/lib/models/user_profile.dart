// lib/models/user_profile.dart

class UserProfile {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String? avatarUrl;
  final String? emergencyContact;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    this.avatarUrl,
    this.emergencyContact,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'emergency_contact': emergencyContact,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? phoneNumber,
    String? fullName,
    String? avatarUrl,
    String? emergencyContact,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
