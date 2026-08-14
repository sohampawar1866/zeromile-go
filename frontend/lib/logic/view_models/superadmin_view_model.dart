// lib/logic/view_models/superadmin_view_model.dart

import 'package:flutter/foundation.dart';
import '../../data/models/group_creation_request.dart';
import '../../data/models/sos_event.dart';
import '../../data/models/user_live_location.dart';
import '../../data/models/sub_group.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/repositories/domain_repository.dart';

class SuperAdminViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final SosRepository _sosRepository;
  final BroadcastRepository _broadcastRepository;
  final DomainRepository _domainRepository;

  List<GroupCreationRequest> _pendingRequests = [];
  List<SosEvent> _escalatedSosQueue = [];
  List<SubGroup> _subGroups = [];
  final List<UserLiveLocation> _liveLocations = [];
  String _selectedGroupFilter = '';
  bool _isLoading = false;
  String? _errorMessage;

  SuperAdminViewModel({
    GroupRepository? groupRepository,
    SosRepository? sosRepository,
    BroadcastRepository? broadcastRepository,
    DomainRepository? domainRepository,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _sosRepository = sosRepository ?? SosRepository(),
        _broadcastRepository = broadcastRepository ?? BroadcastRepository(),
        _domainRepository = domainRepository ?? DomainRepository();

  List<GroupCreationRequest> get pendingRequests => _pendingRequests;
  List<SosEvent> get escalatedSosQueue => _escalatedSosQueue;
  List<SubGroup> get subGroups => _subGroups;
  List<UserLiveLocation> get liveLocations => _liveLocations;
  String get selectedGroupFilter => _selectedGroupFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedGroupFilter(String groupId) {
    _selectedGroupFilter = groupId;
    notifyListeners();
  }

  Future<void> loadAdminContext(String domainId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _groupRepository.fetchPendingGroupRequests(domainId),
        _sosRepository.fetchSuperAdminSosQueue(domainId),
        _groupRepository.fetchDomainSubGroups(domainId),
      ]);
      _pendingRequests = results[0] as List<GroupCreationRequest>;
      _escalatedSosQueue = results[1] as List<SosEvent>;
      _subGroups = results[2] as List<SubGroup>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reviewGroupProposal({
    required String requestId,
    required String reviewerUserId,
    required bool approve,
  }) async {
    try {
      await _groupRepository.reviewGroupRequest(
        requestId: requestId,
        reviewerUserId: reviewerUserId,
        approve: approve,
      );
      _pendingRequests.removeWhere((r) => r.id == requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> resolveSosIncident({
    required String sosId,
    required String adminUserId,
  }) async {
    try {
      await _sosRepository.resolveSosByAdmin(
        sosId: sosId,
        adminUserId: adminUserId,
      );
      _escalatedSosQueue.removeWhere((s) => s.id == sosId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> sendDomainBroadcast({
    required String domainId,
    required String adminUserId,
    required String messageText,
    String? targetGroupId,
  }) async {
    try {
      await _broadcastRepository.sendSuperAdminBroadcast(
        domainId: domainId,
        adminUserId: adminUserId,
        messageText: messageText,
        targetGroupId: targetGroupId,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> updateRouteAndSchedule({
    required String domainId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    Map<String, dynamic>? routeGeojson,
  }) async {
    try {
      await _domainRepository.updateRouteAndSchedule(
        domainId: domainId,
        startTime: startTime,
        endTime: endTime,
        status: status,
        routeGeojson: routeGeojson,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }
}
