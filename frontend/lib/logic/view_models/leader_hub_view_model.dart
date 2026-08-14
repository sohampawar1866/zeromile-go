// lib/logic/view_models/leader_hub_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/group_membership.dart';
import '../../models/sos_event.dart';
import '../../models/user_live_location.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../../data/repositories/telemetry_repository.dart';
import '../../data/repositories/broadcast_repository.dart';

class LeaderHubViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final SosRepository _sosRepository;
  final TelemetryRepository _telemetryRepository;
  final BroadcastRepository _broadcastRepository;

  List<GroupMembership> _roster = [];
  List<SosEvent> _teamSosAlerts = [];
  List<UserLiveLocation> _teamLocations = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<UserLiveLocation>>? _telemetrySub;

  LeaderHubViewModel({
    GroupRepository? groupRepository,
    SosRepository? sosRepository,
    TelemetryRepository? telemetryRepository,
    BroadcastRepository? broadcastRepository,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _sosRepository = sosRepository ?? SosRepository(),
        _telemetryRepository = telemetryRepository ?? TelemetryRepository(),
        _broadcastRepository = broadcastRepository ?? BroadcastRepository();

  List<GroupMembership> get roster => _roster;
  List<SosEvent> get teamSosAlerts => _teamSosAlerts;
  List<UserLiveLocation> get teamLocations => _teamLocations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalMembers => _roster.length;
  int get totalEnrolled => _roster.length;
  int get activeToday => _teamLocations.isNotEmpty ? _teamLocations.length : _roster.where((m) => m.isActive).length;
  int get checkedInCount => _roster.where((m) => m.participationStatus == ParticipationStatus.checkedIn).length;
  int get checkedInMuster => checkedInCount;
  int get completedCount => _roster.where((m) => m.participationStatus == ParticipationStatus.completed).length;
  double get checkinPercent => _roster.isEmpty ? 0.0 : (checkedInCount / _roster.length) * 100.0;
  double get completionPercent => _roster.isEmpty ? 0.0 : (completedCount / _roster.length) * 100.0;

  Future<bool> directAddMember({
    required String domainId,
    required String groupId,
    required String leaderUserId,
    required String memberPhone,
    required String memberName,
  }) {
    return directAddMemberByPhone(
      domainId: domainId,
      groupId: groupId,
      leaderUserId: leaderUserId,
      memberPhone: memberPhone,
      memberName: memberName,
    );
  }

  Future<void> loadLeaderContext({
    required String domainId,
    required String groupId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _roster = await _groupRepository.fetchGroupRoster(domainId: domainId, groupId: groupId);
      _teamSosAlerts = await _sosRepository.fetchGroupLeaderSosAlerts(domainId: domainId, groupId: groupId);

      _telemetrySub?.cancel();
      _telemetrySub = _telemetryRepository.streamGroupTelemetry(domainId, groupId).listen(
        (locations) {
          _teamLocations = locations;
          notifyListeners();
        },
        onError: (_) {},
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> directAddMemberByPhone({
    required String domainId,
    required String groupId,
    required String leaderUserId,
    required String memberPhone,
    required String memberName,
  }) async {
    try {
      await _groupRepository.leaderDirectAddMember(
        domainId: domainId,
        groupId: groupId,
        leaderUserId: leaderUserId,
        memberPhone: memberPhone,
        memberName: memberName,
      );
      _roster = await _groupRepository.fetchGroupRoster(domainId: domainId, groupId: groupId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendTeamBroadcast({
    required String domainId,
    required String leaderUserId,
    required String groupId,
    required String messageText,
  }) async {
    try {
      await _broadcastRepository.sendGroupLeaderBroadcast(
        domainId: domainId,
        leaderUserId: leaderUserId,
        groupId: groupId,
        messageText: messageText,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> resolveSosLocally({
    required String sosId,
    required String leaderUserId,
    required String domainId,
    required String groupId,
  }) async {
    try {
      await _sosRepository.resolveSosLocally(sosId: sosId, leaderUserId: leaderUserId);
      _teamSosAlerts = await _sosRepository.fetchGroupLeaderSosAlerts(domainId: domainId, groupId: groupId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> forwardSosToAdmin({
    required String sosId,
    required String leaderUserId,
    required String leaderNotes,
    required String domainId,
    required String groupId,
  }) async {
    try {
      await _sosRepository.forwardSosToSuperAdmin(
        sosId: sosId,
        leaderUserId: leaderUserId,
        leaderNotes: leaderNotes,
      );
      _teamSosAlerts = await _sosRepository.fetchGroupLeaderSosAlerts(domainId: domainId, groupId: groupId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }
}
