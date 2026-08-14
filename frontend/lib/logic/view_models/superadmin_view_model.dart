// lib/logic/view_models/superadmin_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/group_creation_request.dart';
import '../../models/sos_event.dart';
import '../../models/user_live_location.dart';
import '../../models/sub_group.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/sos_repository.dart';
import '../../data/repositories/telemetry_repository.dart';
import '../../data/repositories/broadcast_repository.dart';
import '../../data/repositories/domain_repository.dart';

class SuperAdminViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final SosRepository _sosRepository;
  final TelemetryRepository _telemetryRepository;
  final BroadcastRepository _broadcastRepository;
  final DomainRepository _domainRepository;

  List<GroupCreationRequest> _pendingRequests = [];
  List<SosEvent> _escalatedSosQueue = [];
  List<UserLiveLocation> _allParticipantLocations = [];
  List<SubGroup> _domainGroups = [];
  String _selectedGroupFilter = '';
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<SosEvent>>? _sosSub;
  StreamSubscription<List<UserLiveLocation>>? _telemetrySub;

  SuperAdminViewModel({
    GroupRepository? groupRepository,
    SosRepository? sosRepository,
    TelemetryRepository? telemetryRepository,
    BroadcastRepository? broadcastRepository,
    DomainRepository? domainRepository,
  })  : _groupRepository = groupRepository ?? GroupRepository(),
        _sosRepository = sosRepository ?? SosRepository(),
        _telemetryRepository = telemetryRepository ?? TelemetryRepository(),
        _broadcastRepository = broadcastRepository ?? BroadcastRepository(),
        _domainRepository = domainRepository ?? DomainRepository();

  List<GroupCreationRequest> get pendingRequests => _pendingRequests;
  List<SosEvent> get escalatedSosQueue => _escalatedSosQueue;
  List<UserLiveLocation> get allParticipantLocations => _allParticipantLocations;
  List<SubGroup> get domainGroups => _domainGroups;
  List<SubGroup> get subGroups => _domainGroups;
  String get selectedGroupFilter => _selectedGroupFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setSelectedGroupFilter(String groupId) {
    _selectedGroupFilter = groupId;
    notifyListeners();
  }

  int get activeRiderCount => _allParticipantLocations.length;

  Future<void> loadAdminContext(String domainId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingRequests = await _groupRepository.fetchPendingGroupRequests(domainId);
      _escalatedSosQueue = await _sosRepository.fetchSuperAdminSosQueue(domainId);
      _domainGroups = await _groupRepository.fetchDomainSubGroups(domainId);

      _sosSub?.cancel();
      _sosSub = _sosRepository.streamSosEvents(domainId).listen(
        (events) {
          _escalatedSosQueue = events;
          notifyListeners();
        },
        onError: (_) {},
      );

      _subscribeTelemetry(domainId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setGroupFilter(String domainId, String groupId) {
    _selectedGroupFilter = groupId;
    _subscribeTelemetry(domainId);
    notifyListeners();
  }

  void _subscribeTelemetry(String domainId) {
    _telemetrySub?.cancel();
    _telemetrySub = _telemetryRepository
        .streamDomainTelemetry(domainId, subGroupIdFilter: _selectedGroupFilter.isEmpty ? null : _selectedGroupFilter)
        .listen(
      (locations) {
        _allParticipantLocations = locations;
        notifyListeners();
      },
      onError: (_) {},
    );
  }

  Future<bool> reviewGroupProposal({
    required String requestId,
    String? adminUserId,
    String? reviewerUserId,
    required bool approve,
    String domainId = 'cycling-2026',
  }) async {
    final effectiveAdminId = adminUserId ?? reviewerUserId ?? 'admin';
    try {
      await _groupRepository.reviewGroupRequest(
        requestId: requestId,
        reviewerUserId: effectiveAdminId,
        approve: approve,
      );
      _pendingRequests = await _groupRepository.fetchPendingGroupRequests(domainId);
      _domainGroups = await _groupRepository.fetchDomainSubGroups(domainId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
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
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    _telemetrySub?.cancel();
    super.dispose();
  }
}
