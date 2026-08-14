// lib/logic/view_models/participant_home_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/broadcast_message.dart';
import '../../models/group_membership.dart';
import '../../models/sos_event.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../../data/repositories/telemetry_repository.dart';

class ParticipantHomeViewModel extends ChangeNotifier {
  final BroadcastRepository _broadcastRepository;
  final GroupRepository _groupRepository;
  final SosRepository _sosRepository;
  final TelemetryRepository _telemetryRepository;

  List<BroadcastMessage> _broadcasts = [];
  List<GroupMembership> _userMemberships = [];
  GroupMembership? _activeMembership;
  bool _isLoading = false;
  bool _isGpsSimulating = false;
  String? _errorMessage;

  StreamSubscription<BroadcastMessage>? _broadcastSubscription;

  ParticipantHomeViewModel({
    BroadcastRepository? broadcastRepository,
    GroupRepository? groupRepository,
    SosRepository? sosRepository,
    TelemetryRepository? telemetryRepository,
  })  : _broadcastRepository = broadcastRepository ?? BroadcastRepository(),
        _groupRepository = groupRepository ?? GroupRepository(),
        _sosRepository = sosRepository ?? SosRepository(),
        _telemetryRepository = telemetryRepository ?? TelemetryRepository();

  List<BroadcastMessage> get broadcasts => _broadcasts;
  List<GroupMembership> get userMemberships => _userMemberships;
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
      _userMemberships = await _groupRepository.fetchUserMemberships(
        domainId: domainId,
        userId: userId,
      );

      if (_userMemberships.isNotEmpty) {
        _activeMembership = _userMemberships.firstWhere(
          (m) => m.isActive,
          orElse: () => _userMemberships.first,
        );
      } else {
        _activeMembership = GroupMembership(
          id: 'demo-vnit-membership',
          domainId: domainId,
          groupId: 'g0000000-0000-0000-0000-000000000002',
          userId: userId,
          isActive: true,
          isLeader: false,
          participationStatus: ParticipationStatus.notCheckedIn,
          joinedAt: DateTime.now(),
          groupName: 'VNIT Cycling Club',
        );
      }

      final enrolledGroupIds = _userMemberships.map((m) => m.groupId).toList();
      _broadcasts = await _broadcastRepository.fetchVisibleBroadcasts(
        domainId: domainId,
        enrolledGroupIds: enrolledGroupIds,
      );

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
    _broadcastSubscription = _broadcastRepository.streamNewBroadcasts(domainId).listen(
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
      await _groupRepository.checkInParticipant(
        domainId: domainId,
        groupId: _activeMembership!.groupId,
        userId: userId,
      );
      _activeMembership = _activeMembership!.copyWith(
        participationStatus: ParticipationStatus.checkedIn,
        checkinTime: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> completeRally({
    required String domainId,
    required String userId,
  }) async {
    if (_activeMembership == null) return false;
    try {
      await _groupRepository.completeEventParticipant(
        domainId: domainId,
        groupId: _activeMembership!.groupId,
        userId: userId,
      );
      _activeMembership = _activeMembership!.copyWith(
        participationStatus: ParticipationStatus.completed,
        completionTime: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  void toggleGpsSimulation({
    required String domainId,
    required String userId,
  }) {
    _isGpsSimulating = !_isGpsSimulating;
    if (_isGpsSimulating) {
      _telemetryRepository.publishLocation(
        domainId: domainId,
        userId: userId,
        activeGroupId: _activeMembership?.groupId,
        latitude: 21.1465,
        longitude: 79.0882,
        speedKmh: 21.6,
        heading: 180.0,
        force: true,
      );
    }
    notifyListeners();
  }

  Future<bool> triggerEmergencySos({
    required String domainId,
    required String userId,
    required EmergencyType emergencyType,
    double latitude = 21.1420,
    double longitude = 79.0810,
  }) async {
    try {
      await _sosRepository.triggerSos(
        domainId: domainId,
        senderUserId: userId,
        activeSubGroupId: _activeMembership?.groupId,
        emergencyType: emergencyType,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  @override
  void dispose() {
    _broadcastSubscription?.cancel();
    super.dispose();
  }
}
