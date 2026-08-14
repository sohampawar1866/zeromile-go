// lib/models/event_domain.dart

enum EventDomainType { cycling, marathon, protest, walkathon, other }
enum EventDomainStatus { upcoming, liveActive, concluded, archived }

class EventDomain {
  final String id;
  final String name;
  final String slug;
  final EventDomainType type;
  final EventDomainStatus status;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic>? routeGeojson;
  final DateTime createdAt;

  EventDomain({
    required this.id,
    required this.name,
    required this.slug,
    required this.type,
    required this.status,
    required this.startTime,
    required this.endTime,
    this.routeGeojson,
    required this.createdAt,
  });

  factory EventDomain.fromJson(Map<String, dynamic> json) {
    return EventDomain(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      type: _parseType(json['type'] as String?),
      status: _parseStatus(json['status'] as String?),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'].toString())
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'].toString())
          : DateTime.now(),
      routeGeojson: json['route_geojson'] != null
          ? Map<String, dynamic>.from(json['route_geojson'] as Map)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'type': _typeToString(type),
      'status': _statusToString(status),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'route_geojson': routeGeojson,
      'created_at': createdAt.toIso8601String(),
    };
  }

  EventDomain copyWith({
    String? id,
    String? name,
    String? slug,
    EventDomainType? type,
    EventDomainStatus? status,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? routeGeojson,
    DateTime? createdAt,
  }) {
    return EventDomain(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      routeGeojson: routeGeojson ?? this.routeGeojson,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isCurrentlyLive {
    final now = DateTime.now();
    return status == EventDomainStatus.liveActive &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  static EventDomainType _parseType(String? str) {
    switch (str?.toUpperCase()) {
      case 'CYCLING':
        return EventDomainType.cycling;
      case 'MARATHON':
        return EventDomainType.marathon;
      case 'PROTEST':
        return EventDomainType.protest;
      case 'WALKATHON':
        return EventDomainType.walkathon;
      default:
        return EventDomainType.other;
    }
  }

  static String _typeToString(EventDomainType t) {
    switch (t) {
      case EventDomainType.cycling:
        return 'CYCLING';
      case EventDomainType.marathon:
        return 'MARATHON';
      case EventDomainType.protest:
        return 'PROTEST';
      case EventDomainType.walkathon:
        return 'WALKATHON';
      case EventDomainType.other:
        return 'OTHER';
    }
  }

  static EventDomainStatus _parseStatus(String? str) {
    switch (str?.toUpperCase()) {
      case 'LIVE_ACTIVE':
        return EventDomainStatus.liveActive;
      case 'CONCLUDED':
        return EventDomainStatus.concluded;
      case 'ARCHIVED':
        return EventDomainStatus.archived;
      case 'UPCOMING':
      default:
        return EventDomainStatus.upcoming;
    }
  }

  static String _statusToString(EventDomainStatus s) {
    switch (s) {
      case EventDomainStatus.liveActive:
        return 'LIVE_ACTIVE';
      case EventDomainStatus.concluded:
        return 'CONCLUDED';
      case EventDomainStatus.archived:
        return 'ARCHIVED';
      case EventDomainStatus.upcoming:
        return 'UPCOMING';
    }
  }
}
