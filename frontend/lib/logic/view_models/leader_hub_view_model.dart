// lib/logic/view_models/leader_hub_view_model.dart

import 'package:flutter/foundation.dart';
import '../../data/models/group_membership.dart';
import '../../data/models/sos_event.dart';
import '../../data/models/user_live_location.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../../data/repositories/broadcast_repository.dart';

class LeaderHubViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final SosRepository _sosRepository;
  final BroadcastRepository _broadcastRepository;

  List<GroupMembership> _roster = [];
  List<SosEvent> _teamSosAlerts = [];
  final List<UserLiveLocation> _teamTelemetry = [];
  bool _isLoading = false;
  String? _errorMessage;

  LeaderHubViewModel({
    GroupRepository? groupRepository,
    SosRepository? sosRepository,
    BroadcastRepository? broadcastRepository,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _sosRepository = sosRepository ?? SosRepository(),
        _broadcastRepository = broadcastRepository ?? BroadcastRepository();

  List<GroupMembership> get roster => _roster;
  List<SosEvent> get teamSosAlerts => _teamSosAlerts;
  List<UserLiveLocation> get teamTelemetry => _teamTelemetry;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Analytics Metrics
  int get totalEnrolled => _roster.length;
  int get activeToday => _roster.where((m) => m.isActive).length;
  int get checkedInMuster => _roster.where((m) => m.participationStatus == ParticipationStatus.checkedIn).length;
  int get completedCount => _roster.where((m) => m.participationStatus == ParticipationStatus.completed).length;
  double get checkinPercent => totalEnrolled > 0 ? (checkedInMuster / totalEnrolled) * 100 : 0.0;
  double get completionPercent => totalEnrolled > 0 ? (completedCount / totalEnrolled) * 100 : 0.0;

  Future<void> loadLeaderContext({
    required String domainId,
    required String groupId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _groupRepository.fetchGroupRoster(domainId: domainId, groupId: groupId),
        _sosRepository.fetchGroupLeaderSosAlerts(domainId: domainId, groupId: groupId),
      ]);
      _roster = results[0] as List<GroupMembership>;
      _teamSosAlerts = results[1] as List<SosEvent>;
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
    try {
      await _groupRepository.leaderDirectAddMember(
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
      await _sosRepository.resolveSosLocally(
        sosId: sosId,
        leaderUserId: leaderUserId,
      );
      _teamSosAlerts.removeWhere((s) => s.id == sosId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> forwardSosToAdmin({
    required String sosId,
    required String leaderUserId,
    required String leaderNotes,
  }) async {
    try {
      await _sosRepository.forwardSosToSuperAdmin(
        sosId: sosId,
        leaderUserId: leaderUserId,
        leaderNotes: leaderNotes,
      );
      _teamSosAlerts.removeWhere((s) => s.id == sosId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
