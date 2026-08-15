// lib/logic/view_models/participant_home_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/broadcast_message.dart';
import '../../models/group_membership.dart';
import '../../models/route_checkpoint.dart';
import '../../models/sos_event.dart';
import '../../models/user_live_location.dart';
import '../../services/broadcast_service.dart';
import '../../services/domain_service.dart';
import '../../services/group_service.dart';
import '../../services/sos_service.dart';
import '../../services/location_telemetry_service.dart';

class ParticipantHomeViewModel extends ChangeNotifier {
  final BroadcastService _broadcastService;
  final GroupService _groupService;
  final SosService _sosService;
  final LocationTelemetryService _telemetryService;
  final DomainService _domainService;

  List<BroadcastMessage> _broadcasts = [];
  List<GroupMembership> _userMemberships = [];
  List<RouteCheckpoint> _checkpoints = [];
  List<UserLiveLocation> _groupMemberLocations = [];
  GroupMembership? _activeMembership;
  bool _isLoading = false;
  bool _isGpsSimulating = false;
  String? _errorMessage;

  StreamSubscription<BroadcastMessage>? _broadcastSubscription;
  StreamSubscription<List<UserLiveLocation>>? _groupTelemetrySub;

  ParticipantHomeViewModel({
    BroadcastService? broadcastService,
    GroupService? groupService,
    SosService? sosService,
    LocationTelemetryService? telemetryService,
    DomainService? domainService,
  })  : _broadcastService = broadcastService ?? BroadcastService(),
        _groupService = groupService ?? GroupService(),
        _sosService = sosService ?? SosService(),
        _telemetryService = telemetryService ?? LocationTelemetryService(),
        _domainService = domainService ?? DomainService();

  List<BroadcastMessage> get broadcasts => _broadcasts;
  List<GroupMembership> get userMemberships => _userMemberships;
  List<RouteCheckpoint> get checkpoints => _checkpoints;
  /// Live locations of this participant's group members (empty if solo).
  List<UserLiveLocation> get groupMemberLocations => _groupMemberLocations;
  GroupMembership? get activeMembership => _activeMembership;
  bool get isLoading => _isLoading;
  bool get isGpsSimulating => _isGpsSimulating;
  String? get errorMessage => _errorMessage;

  Future<void> loadParticipantContext({
    required String domainId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userMemberships = await _groupService.getUserMemberships(
        domainId: domainId,
        userId: userId,
      );

      if (_userMemberships.isNotEmpty) {
        _activeMembership = _userMemberships.firstWhere(
          (m) => m.isActive,
          orElse: () => _userMemberships.first,
        );
      } else {
        _activeMembership = null;
      }

      final enrolledGroupIds = _userMemberships.map((m) => m.groupId).toList();
      _broadcasts = await _broadcastService.getVisibleBroadcasts(
        domainId: domainId,
        enrolledGroupIds: enrolledGroupIds,
      );

      _checkpoints = await _domainService.getRouteCheckpoints(domainId);

      // Subscribe to group member live locations (if in a group)
      if (_activeMembership != null) {
        _groupTelemetrySub?.cancel();
        _groupTelemetrySub = _telemetryService
            .streamGroupTelemetry(domainId, _activeMembership!.groupId)
            .listen(
          (locations) {
            // Exclude own location (userId matches userId arg)
            _groupMemberLocations = locations
                .where((l) => l.userId != userId)
                .toList();
            notifyListeners();
          },
          onError: (_) {},
        );
      }

      _setupRealtimeBroadcasts(domainId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtimeBroadcasts(String domainId) {
    _broadcastSubscription?.cancel();
    _broadcastSubscription = _broadcastService.streamNewBroadcasts(domainId).listen(
      (newMsg) {
        _broadcasts.insert(0, newMsg);
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<bool> checkInAtMuster({
    required String domainId,
    required String userId,
  }) async {
    if (_activeMembership == null) return false;
    try {
      await _groupService.checkInParticipant(
        domainId: domainId,
        groupId: _activeMembership!.groupId,
        userId: userId,
      );
      await loadParticipantContext(domainId: domainId, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeRally({
    required String domainId,
    required String userId,
  }) async {
    if (_activeMembership == null) return false;
    try {
      await _groupService.completeEventParticipant(
        domainId: domainId,
        groupId: _activeMembership!.groupId,
        userId: userId,
      );
      await loadParticipantContext(domainId: domainId, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeEvent({
    required String domainId,
    required String userId,
  }) => completeRally(domainId: domainId, userId: userId);

  /// Trigger emergency SOS. [type] is a string label like 'medical', 'crash', etc.
  Future<bool> triggerEmergencySos({
    required String domainId,
    required String userId,
    String type = 'medical',
    double latitude = 21.1466,
    double longitude = 79.0888,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isSubGroupActive = _activeMembership != null &&
          _activeMembership!.groupName != null &&
          !_activeMembership!.groupName!.toLowerCase().contains('general');

      final activeSubGroupId =
          isSubGroupActive ? _activeMembership!.groupId : null;

      // Map string type to enum
      final eType = type == 'crash'
          ? EmergencyType.breakdown
          : type == 'mechanical'
              ? EmergencyType.breakdown
              : type == 'threat'
                  ? EmergencyType.threat
                  : type == 'lost'
                      ? EmergencyType.lost
                      : EmergencyType.medical;

      await _sosService.triggerSos(
        domainId: domainId,
        senderUserId: userId,
        activeSubGroupId: activeSubGroupId,
        emergencyType: eType,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startGpsTelemetry({
    required String domainId,
    required String userId,
  }) {
    _isGpsSimulating = true;
    final activeGroupId = _activeMembership?.groupId;
    _telemetryService.startHardwareTelemetryDaemon(
      domainId: domainId,
      userId: userId,
      activeGroupId: activeGroupId,
    );
    notifyListeners();
  }

  void stopGpsTelemetry() {
    _isGpsSimulating = false;
    _telemetryService.stopHardwareTelemetryDaemon();
    notifyListeners();
  }

  void startGpsSimulation({
    required String domainId,
    required String userId,
  }) => startGpsTelemetry(domainId: domainId, userId: userId);

  void stopGpsSimulation() => stopGpsTelemetry();

  @override
  void dispose() {
    _broadcastSubscription?.cancel();
    _groupTelemetrySub?.cancel();
    _telemetryService.stopHardwareTelemetryDaemon();
    super.dispose();
  }
}
