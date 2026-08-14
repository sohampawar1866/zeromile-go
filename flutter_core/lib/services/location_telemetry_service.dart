// lib/services/location_telemetry_service.dart

import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_live_location.dart';
import 'supabase_client_service.dart';

class LocationTelemetryService {
  final SupabaseClient _client;
  final List<RealtimeChannel> _activeChannels = [];

  // Throttling state
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastPingTime;
  static const int minPingIntervalSeconds = 5;
  static const double minDistanceDeltaMeters = 5.0;

  // Offline buffer queue
  final List<Map<String, dynamic>> _offlineQueue = [];

  LocationTelemetryService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  /// Throttled GPS publisher: Publishes ONLY if moved >= 5m or interval >= 5s
  Future<bool> publishLocationPing({
    required String domainId,
    required String userId,
    String? activeGroupId,
    required double latitude,
    required double longitude,
    double speedKmh = 0.0,
    double heading = 0.0,
    bool force = false,
  }) async {
    // 1. Guard against invalid GPS readings (e.g. 0.0, 0.0 or NaN before satellite lock)
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude == 0.0 && longitude == 0.0) return false;
    if (latitude < -90.0 || latitude > 90.0 || longitude < -180.0 || longitude > 180.0) return false;

    final now = DateTime.now();

    // 2. Adaptive GPS throttling
    if (!force && _lastPingTime != null && _lastLatitude != null && _lastLongitude != null) {
      final elapsed = now.difference(_lastPingTime!).inSeconds;
      final distMeters = _distanceMeters(_lastLatitude!, _lastLongitude!, latitude, longitude);

      if (elapsed < minPingIntervalSeconds && distMeters < minDistanceDeltaMeters) {
        return false; // Throttled
      }
    }

    _lastLatitude = latitude;
    _lastLongitude = longitude;
    _lastPingTime = now;

    final payload = {
      'domain_id': domainId,
      'user_id': userId,
      'active_group_id': activeGroupId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmh.isNaN ? 0.0 : speedKmh,
      'heading': heading.isNaN ? 0.0 : heading,
      'updated_at': now.toIso8601String(),
    };

    try {
      await _client
          .from('user_live_locations')
          .upsert(payload, onConflict: 'domain_id,user_id');

      // Flush offline queue if network was restored
      if (_offlineQueue.isNotEmpty) {
        final toFlush = List<Map<String, dynamic>>.from(_offlineQueue);
        _offlineQueue.clear();
        for (final item in toFlush) {
          try {
            await _client.from('user_live_locations').upsert(item, onConflict: 'domain_id,user_id');
          } catch (_) {
            _offlineQueue.add(item);
          }
        }
      }

      return true;
    } catch (_) {
      // Buffer in offline queue for auto-retry
      _offlineQueue.add(payload);
      if (_offlineQueue.length > 30) _offlineQueue.removeAt(0);
      return false;
    }
  }

  /// SuperAdmin Console: Stream all domain participant pings (with optional group filter)
  Stream<List<UserLiveLocation>> streamDomainTelemetry(
    String domainId, {
    String? subGroupIdFilter,
  }) {
    late final StreamController<List<UserLiveLocation>> controller;
    RealtimeChannel? channel;

    void fetchAndEmit() {
      var query = _client
          .from('user_live_locations')
          .select('*, users(full_name)')
          .eq('domain_id', domainId);

      if (subGroupIdFilter != null && subGroupIdFilter.isNotEmpty) {
        query = query.eq('active_group_id', subGroupIdFilter);
      }

      query.then((data) {
        final list = (data as List).map((j) => UserLiveLocation.fromJson(j)).toList();
        if (!controller.isClosed) {
          controller.add(list);
        }
      }).catchError((e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      });
    }

    controller = StreamController<List<UserLiveLocation>>.broadcast(
      onListen: () {
        fetchAndEmit();

        final channelName = 'realtime:telemetry:$domainId:${DateTime.now().millisecondsSinceEpoch}';
        channel = _client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'user_live_locations',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'domain_id',
                value: domainId,
              ),
              callback: (payload) => fetchAndEmit(),
            )
            .subscribe();

        _activeChannels.add(channel!);
      },
      onCancel: () {
        if (channel != null) {
          channel!.unsubscribe();
          _client.removeChannel(channel!);
          _activeChannels.remove(channel);
        }
      },
    );

    return controller.stream;
  }

  /// Group Leader Hub: Stream only team members in their specific contingent
  Stream<List<UserLiveLocation>> streamGroupTelemetry(
    String domainId,
    String groupId,
  ) {
    return streamDomainTelemetry(domainId, subGroupIdFilter: groupId);
  }

  /// Clean up all active telemetry channels
  void dispose() {
    for (final channel in List<RealtimeChannel>.from(_activeChannels)) {
      channel.unsubscribe();
      _client.removeChannel(channel);
    }
    _activeChannels.clear();
  }

  static double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}
