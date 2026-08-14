// lib/logic/view_models/leader_hub_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/group_membership.dart';
import '../../models/sos_event.dart';
import '../../models/user_live_location.dart';
import '../../services/group_service.dart';
import '../../services/sos_service.dart';
import '../../services/location_telemetry_service.dart';
import '../../services/broadcast_service.dart';

class LeaderHubViewModel extends ChangeNotifier {
  final GroupService _groupService;
  final SosService _sosService;
  final LocationTelemetryService _telemetryService;
  final BroadcastService _broadcastService;

  List<GroupMembership> _roster = [];
  List<SosEvent> _teamSosAlerts = [];
  List<UserLiveLocation> _teamLocations = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<UserLiveLocation>>? _telemetrySub;

  LeaderHubViewModel({
    GroupService? groupService,
    SosService? sosService,
    LocationTelemetryService? telemetryService,
    BroadcastService? broadcastService,
  })  : _groupService = groupService ?? GroupService(),
        _sosService = sosService ?? SosService(),
        _telemetryService = telemetryService ?? LocationTelemetryService(),
        _broadcastService = broadcastService ?? BroadcastService();

  List<GroupMembership> get roster => _roster;
  List<SosEvent> get teamSosAlerts => _teamSosAlerts;
  List<UserLiveLocation> get teamLocations => _teamLocations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalMembers => _roster.length;
  int get totalEnrolled => _roster.length;
  String get groupName => _roster.firstOrNull?.groupName ?? 'Contingent Group';
  int get activeToday => _teamLocations.isNotEmpty ? _teamLocations.length : _roster.where((m) => m.isActive).length;
  int get checkedInCount => _roster.where((m) => m.participationStatus == ParticipationStatus.checkedIn).length;
  int get checkedInMuster => checkedInCount;
  int get completedCount => _roster.where((m) => m.participationStatus == ParticipationStatus.completed).length;
  double get checkinPercent => _roster.isEmpty ? 0.0 : (checkedInCount / _roster.length) * 100.0;
  double get completionPercent => _roster.isEmpty ? 0.0 : (completedCount / _roster.length) * 100.0;

  Future<void> loadLeaderContext({
    required String domainId,
    required String groupId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _roster = await _groupService.getGroupRoster(domainId: domainId, groupId: groupId);
      _teamSosAlerts = await _sosService.getGroupLeaderSosAlerts(domainId: domainId, groupId: groupId);

      _telemetrySub?.cancel();
      _telemetrySub = _telemetryService.streamGroupTelemetry(domainId, groupId).listen(
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

  Future<bool> directAddMember({
    required String domainId,
    required String groupId,
    required String leaderUserId,
    required String memberPhone,
    required String memberName,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _groupService.leaderDirectAddMember(
        domainId: domainId,
        groupId: groupId,
        leaderUserId: leaderUserId,
        memberPhone: memberPhone,
        memberName: memberName,
      );
      await loadLeaderContext(domainId: domainId, groupId: groupId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
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
  }) => directAddMember(
        domainId: domainId,
        groupId: groupId,
        leaderUserId: leaderUserId,
        memberPhone: memberPhone,
        memberName: memberName,
      );

  Future<bool> resolveSosLocally({
    required String sosId,
    required String leaderUserId,
    required String domainId,
    required String groupId,
  }) async {
    try {
      await _sosService.resolveSosLocally(
        sosId: sosId,
        leaderUserId: leaderUserId,
      );
      _teamSosAlerts.removeWhere((sos) => sos.id == sosId);
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
      await _sosService.forwardSosToSuperAdmin(
        sosId: sosId,
        leaderUserId: leaderUserId,
        leaderNotes: leaderNotes,
      );
      _teamSosAlerts.removeWhere((sos) => sos.id == sosId);
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
      await _broadcastService.sendGroupLeaderBroadcast(
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

  @override
  void dispose() {
    _telemetrySub?.cancel();
    super.dispose();
  }
}
