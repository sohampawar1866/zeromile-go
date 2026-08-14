// lib/services/broadcast_service.dart

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/broadcast_message.dart';
import 'supabase_client_service.dart';

class BroadcastService {
  final SupabaseClient _client;
  RealtimeChannel? _activeBroadcastChannel;

  BroadcastService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  /// SuperAdmin Console: Dispatch domain-wide or sub-group broadcast
  Future<BroadcastMessage> sendSuperAdminBroadcast({
    required String domainId,
    required String adminUserId,
    required String messageText,
    String? targetGroupId, // null for General domain-wide
  }) async {
    final inserted = await _client
        .from('broadcasts')
        .insert({
          'domain_id': domainId,
          'sender_id': adminUserId,
          'sender_role': 'SUPERADMIN',
          'target_type': targetGroupId != null ? 'SPECIFIC_GROUP' : 'GENERAL',
          'target_group_id': targetGroupId,
          'message_text': messageText,
        })
        .select('*, users(full_name)')
        .single();

    return BroadcastMessage.fromJson(inserted);
  }

  /// Group Leader Hub: Dispatch broadcast to own team members only
  Future<BroadcastMessage> sendGroupLeaderBroadcast({
    required String domainId,
    required String leaderUserId,
    required String groupId,
    required String messageText,
  }) async {
    final inserted = await _client
        .from('broadcasts')
        .insert({
          'domain_id': domainId,
          'sender_id': leaderUserId,
          'sender_role': 'GROUP_LEADER',
          'target_type': 'SPECIFIC_GROUP',
          'target_group_id': groupId,
          'message_text': messageText,
        })
        .select('*, users(full_name)')
        .single();

    return BroadcastMessage.fromJson(inserted);
  }

  /// Fetch broadcasts visible to the user (General domain broadcasts + enrolled group broadcasts)
  Future<List<BroadcastMessage>> getVisibleBroadcasts({
    required String domainId,
    List<String> enrolledGroupIds = const [],
  }) async {
    final data = await _client
        .from('broadcasts')
        .select('*, users(full_name)')
        .eq('domain_id', domainId)
        .order('created_at', ascending: false)
        .limit(40);

    final all = (data as List).map((j) => BroadcastMessage.fromJson(j)).toList();

    // Filter in-memory for General OR user's enrolled group IDs
    return all.where((b) {
      if (b.targetType == BroadcastTargetType.general) return true;
      if (b.targetGroupId != null && enrolledGroupIds.contains(b.targetGroupId)) return true;
      return false;
    }).toList();
  }

  /// Realtime Stream for Instant Broadcast Alerts
  Stream<BroadcastMessage> streamNewBroadcasts(String domainId) {
    late final StreamController<BroadcastMessage> controller;
    RealtimeChannel? channel;

    controller = StreamController<BroadcastMessage>.broadcast(
      onListen: () {
        final channelName = 'realtime:broadcasts:$domainId:${DateTime.now().millisecondsSinceEpoch}';
        channel = _client
            .channel(channelName)
            .onPostgresChanges(
              event: PostgresChangeEvent.insert,
              schema: 'public',
              table: 'broadcasts',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'domain_id',
                value: domainId,
              ),
              callback: (payload) {
                try {
                  final newRecord = payload.newRecord;
                  if (!controller.isClosed) {
                    controller.add(BroadcastMessage.fromJson(newRecord));
                  }
                } catch (e, st) {
                  if (!controller.isClosed) {
                    controller.addError(e, st);
                  }
                }
              },
            )
            .subscribe();

        _activeBroadcastChannel = channel;
      },
      onCancel: () {
        if (channel != null) {
          channel!.unsubscribe();
          _client.removeChannel(channel!);
          if (_activeBroadcastChannel == channel) {
            _activeBroadcastChannel = null;
          }
        }
      },
    );

    return controller.stream;
  }

  /// Clean up active broadcast channels
  void dispose() {
    if (_activeBroadcastChannel != null) {
      _activeBroadcastChannel!.unsubscribe();
      _client.removeChannel(_activeBroadcastChannel!);
      _activeBroadcastChannel = null;
    }
  }
}
