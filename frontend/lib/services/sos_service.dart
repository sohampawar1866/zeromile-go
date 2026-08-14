// lib/services/sos_service.dart

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sos_event.dart';
import 'supabase_client_service.dart';

class SosService {
  final SupabaseClient _client;
  RealtimeChannel? _activeSosChannel;

  SosService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  /// Trigger emergency SOS from participant device
  Future<SosEvent> triggerSos({
    required String domainId,
    required String senderUserId,
    String? activeSubGroupId,
    required EmergencyType emergencyType,
    required double latitude,
    required double longitude,
  }) async {
    final inserted = await _client
        .from('sos_events')
        .insert({
          'domain_id': domainId,
          'sender_user_id': senderUserId,
          'active_sub_group_id': activeSubGroupId,
          'emergency_type': _emergencyTypeToString(emergencyType),
          'latitude': latitude,
          'longitude': longitude,
          'status': 'TRIGGERED',
        })
        .select('*, sender:users!sos_events_sender_user_id_fkey(full_name, phone_number), sub_groups(name)')
        .single();

    return SosEvent.fromJson(inserted);
  }

  /// Group Leader Hub: Fetch active SOS alerts for their own group
  Future<List<SosEvent>> getGroupLeaderSosAlerts({
    required String domainId,
    required String groupId,
  }) async {
    final data = await _client
        .from('sos_events')
        .select('*, sender:users!sos_events_sender_user_id_fkey(full_name, phone_number), sub_groups(name)')
        .eq('domain_id', domainId)
        .eq('active_sub_group_id', groupId)
        .neq('status', 'RESOLVED')
        .order('created_at', ascending: false);

    return (data as List).map((json) => SosEvent.fromJson(json)).toList();
  }

  /// Group Leader Hub: Resolve alert locally (first-aid, mechanical help)
  Future<void> resolveSosLocally({
    required String sosId,
    required String leaderUserId,
  }) async {
    await _client.from('sos_events').update({
      'status': 'RESOLVED',
      'resolved_by': leaderUserId,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', sosId);
  }

  /// Group Leader Hub: Forward alert to SuperAdmin with attached note
  Future<void> forwardSosToSuperAdmin({
    required String sosId,
    required String leaderUserId,
    required String leaderNotes,
  }) async {
    await _client.from('sos_events').update({
      'status': 'FORWARDED_TO_ADMIN',
      'forwarded_by_leader_id': leaderUserId,
      'leader_notes': leaderNotes,
    }).eq('id', sosId);
  }

  /// SuperAdmin Console: Fetch escalated queue (forwarded + direct general alerts)
  Future<List<SosEvent>> getSuperAdminSosQueue(String domainId) async {
    final data = await _client
        .from('sos_events')
        .select('*, sender:users!sos_events_sender_user_id_fkey(full_name, phone_number), sub_groups(name)')
        .eq('domain_id', domainId)
        .neq('status', 'RESOLVED')
        .order('created_at', ascending: false);

    return (data as List).map((json) => SosEvent.fromJson(json)).toList();
  }

  /// SuperAdmin Console: Resolve escalated emergency incident
  Future<void> resolveSosByAdmin({
    required String sosId,
    required String adminUserId,
  }) async {
    await _client.from('sos_events').update({
      'status': 'RESOLVED',
      'resolved_by': adminUserId,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', sosId);
  }

  /// Subscribe to Realtime SOS Event Stream for Live Monitoring
  Stream<List<SosEvent>> streamSosEvents(String domainId) {
    late final StreamController<List<SosEvent>> controller;
    RealtimeChannel? channel;

    void pushUpdate() {
      getSuperAdminSosQueue(domainId).then((updatedList) {
        if (!controller.isClosed) {
          controller.add(updatedList);
        }
      }).catchError((e, st) {
        if (!controller.isClosed) {
          controller.addError(e, st);
        }
      });
    }

    controller = StreamController<List<SosEvent>>.broadcast(
      onListen: () {
        pushUpdate();

        final channelName = 'realtime:sos:$domainId:${DateTime.now().millisecondsSinceEpoch}';
        channel = _client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'sos_events',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'domain_id',
                value: domainId,
              ),
              callback: (payload) => pushUpdate(),
            )
            .subscribe();

        _activeSosChannel = channel;
      },
      onCancel: () {
        if (channel != null) {
          channel!.unsubscribe();
          _client.removeChannel(channel!);
          if (_activeSosChannel == channel) {
            _activeSosChannel = null;
          }
        }
      },
    );

    return controller.stream;
  }

  /// Clean up any active subscriptions
  void dispose() {
    if (_activeSosChannel != null) {
      _activeSosChannel!.unsubscribe();
      _client.removeChannel(_activeSosChannel!);
      _activeSosChannel = null;
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
}
