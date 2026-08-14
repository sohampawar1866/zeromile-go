// lib/data/repositories/telemetry_repository.dart

import '../../models/user_live_location.dart';
import '../../services/location_telemetry_service.dart';

class TelemetryRepository {
  final LocationTelemetryService _telemetryService;

  TelemetryRepository({LocationTelemetryService? telemetryService})
      : _telemetryService = telemetryService ?? LocationTelemetryService();

  Future<bool> publishLocation({
    required String domainId,
    required String userId,
    String? activeGroupId,
    required double latitude,
    required double longitude,
    double speedKmh = 0.0,
    double heading = 0.0,
    bool force = false,
  }) async {
    return _telemetryService.publishLocationPing(
      domainId: domainId,
      userId: userId,
      activeGroupId: activeGroupId,
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
      heading: heading,
      force: force,
    );
  }

  Stream<List<UserLiveLocation>> streamDomainTelemetry(String domainId, {String? subGroupIdFilter}) {
    return _telemetryService.streamDomainTelemetry(domainId, subGroupIdFilter: subGroupIdFilter);
  }

  Stream<List<UserLiveLocation>> streamGroupTelemetry(String domainId, String groupId) {
    return _telemetryService.streamGroupTelemetry(domainId, groupId);
  }

  void dispose() {
    _telemetryService.dispose();
  }
}
