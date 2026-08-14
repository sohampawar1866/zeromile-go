// lib/data/repositories/sos_repository.dart

import '../../models/sos_event.dart';
import '../../services/sos_service.dart';

class SosRepository {
  final SosService _sosService;

  SosRepository({SosService? sosService})
      : _sosService = sosService ?? SosService();

  Future<SosEvent> triggerSos({
    required String domainId,
    required String senderUserId,
    String? activeSubGroupId,
    required EmergencyType emergencyType,
    required double latitude,
    required double longitude,
  }) async {
    return _sosService.triggerSos(
      domainId: domainId,
      senderUserId: senderUserId,
      activeSubGroupId: activeSubGroupId,
      emergencyType: emergencyType,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<List<SosEvent>> fetchGroupLeaderSosAlerts({
    required String domainId,
    required String groupId,
  }) async {
    return _sosService.getGroupLeaderSosAlerts(
      domainId: domainId,
      groupId: groupId,
    );
  }

  Future<void> resolveSosLocally({
    required String sosId,
    required String leaderUserId,
  }) async {
    await _sosService.resolveSosLocally(
      sosId: sosId,
      leaderUserId: leaderUserId,
    );
  }

  Future<void> forwardSosToSuperAdmin({
    required String sosId,
    required String leaderUserId,
    required String leaderNotes,
  }) async {
    await _sosService.forwardSosToSuperAdmin(
      sosId: sosId,
      leaderUserId: leaderUserId,
      leaderNotes: leaderNotes,
    );
  }

  Future<List<SosEvent>> fetchSuperAdminSosQueue(String domainId) async {
    return _sosService.getSuperAdminSosQueue(domainId);
  }

  Future<void> resolveSosByAdmin({
    required String sosId,
    required String adminUserId,
  }) async {
    await _sosService.resolveSosByAdmin(
      sosId: sosId,
      adminUserId: adminUserId,
    );
  }

  Stream<List<SosEvent>> streamSosEvents(String domainId) {
    return _sosService.streamSosEvents(domainId);
  }

  void dispose() {
    _sosService.dispose();
  }
}
