// lib/models/route_checkpoint.dart

enum CheckpointType { start, waterStation, medicalPost, diversion, finish }

class RouteCheckpoint {
  final String id;
  final String domainId;
  final CheckpointType checkpointType;
  final String name;
  final double latitude;
  final double longitude;
  final int sequenceOrder;
  final DateTime createdAt;

  RouteCheckpoint({
    required this.id,
    required this.domainId,
    required this.checkpointType,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sequenceOrder,
    required this.createdAt,
  });

  factory RouteCheckpoint.fromJson(Map<String, dynamic> json) {
    return RouteCheckpoint(
      id: json['id'] as String? ?? '',
      domainId: json['domain_id'] as String? ?? '',
      checkpointType: _parseType(json['checkpoint_type'] as String?),
      name: json['name'] as String? ?? 'Checkpoint',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      sequenceOrder: (json['sequence_order'] as num?)?.toInt() ?? 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'domain_id': domainId,
      'checkpoint_type': _typeToString(checkpointType),
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequence_order': sequenceOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RouteCheckpoint copyWith({
    String? id,
    String? domainId,
    CheckpointType? checkpointType,
    String? name,
    double? latitude,
    double? longitude,
    int? sequenceOrder,
    DateTime? createdAt,
  }) {
    return RouteCheckpoint(
      id: id ?? this.id,
      domainId: domainId ?? this.domainId,
      checkpointType: checkpointType ?? this.checkpointType,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static CheckpointType _parseType(String? s) {
    switch (s?.toUpperCase()) {
      case 'START':
        return CheckpointType.start;
      case 'WATER_STATION':
        return CheckpointType.waterStation;
      case 'MEDICAL_POST':
        return CheckpointType.medicalPost;
      case 'DIVERSION':
        return CheckpointType.diversion;
      case 'FINISH':
      default:
        return CheckpointType.finish;
    }
  }

  static String _typeToString(CheckpointType t) {
    switch (t) {
      case CheckpointType.start:
        return 'START';
      case CheckpointType.waterStation:
        return 'WATER_STATION';
      case CheckpointType.medicalPost:
        return 'MEDICAL_POST';
      case CheckpointType.diversion:
        return 'DIVERSION';
      case CheckpointType.finish:
        return 'FINISH';
    }
  }
}
