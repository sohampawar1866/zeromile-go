// lib/data/repositories/broadcast_repository.dart

import '../models/broadcast_message.dart';
import '../services/broadcast_service.dart';

class BroadcastRepository {
  final BroadcastService _broadcastService;

  BroadcastRepository({BroadcastService? broadcastService})
      : _broadcastService = broadcastService ?? BroadcastService();

  Future<BroadcastMessage> sendSuperAdminBroadcast({
    required String domainId,
    required String adminUserId,
    required String messageText,
    String? targetGroupId,
  }) async {
    return _broadcastService.sendSuperAdminBroadcast(
      domainId: domainId,
      adminUserId: adminUserId,
      messageText: messageText,
      targetGroupId: targetGroupId,
    );
  }

  Future<BroadcastMessage> sendGroupLeaderBroadcast({
    required String domainId,
    required String leaderUserId,
    required String groupId,
    required String messageText,
  }) async {
    return _broadcastService.sendGroupLeaderBroadcast(
      domainId: domainId,
      leaderUserId: leaderUserId,
      groupId: groupId,
      messageText: messageText,
    );
  }

  Future<List<BroadcastMessage>> fetchVisibleBroadcasts({
    required String domainId,
    List<String> enrolledGroupIds = const [],
  }) async {
    return _broadcastService.getVisibleBroadcasts(
      domainId: domainId,
      enrolledGroupIds: enrolledGroupIds,
    );
  }

  Stream<BroadcastMessage> streamNewBroadcasts(String domainId) {
    return _broadcastService.streamNewBroadcasts(domainId);
  }

  void dispose() {
    _broadcastService.dispose();
  }
}
