// lib/logic/view_models/superadmin_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/group_creation_request.dart';
import '../../models/sos_event.dart';
import '../../models/user_live_location.dart';
import '../../models/sub_group.dart';
import '../../services/group_service.dart';
import '../../services/sos_service.dart';
import '../../services/location_telemetry_service.dart';
import '../../services/broadcast_service.dart';
import '../../services/domain_service.dart';

class SuperAdminViewModel extends ChangeNotifier {
  final GroupService _groupService;
  final SosService _sosService;
  final LocationTelemetryService _telemetryService;
  final BroadcastService _broadcastService;
  final DomainService _domainService;

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
    GroupService? groupService,
    SosService? sosService,
    LocationTelemetryService? telemetryService,
    BroadcastService? broadcastService,
    DomainService? domainService,
  })  : _groupService = groupService ?? GroupService(),
        _sosService = sosService ?? SosService(),
        _telemetryService = telemetryService ?? LocationTelemetryService(),
        _broadcastService = broadcastService ?? BroadcastService(),
        _domainService = domainService ?? DomainService();

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
      _pendingRequests = await _groupService.getPendingGroupRequests(domainId);
      _escalatedSosQueue = await _sosService.getSuperAdminSosQueue(domainId);
      _domainGroups = await _groupService.getDomainSubGroups(domainId);

      _sosSub?.cancel();
      _sosSub = _sosService.streamSosEvents(domainId).listen(
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
    _telemetrySub = _telemetryService
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
    required String reviewerUserId,
    required bool approve,
  }) async {
    try {
      await _groupService.reviewGroupRequest(
        requestId: requestId,
        reviewerUserId: reviewerUserId,
        approve: approve,
      );
      _pendingRequests.removeWhere((req) => req.id == requestId);
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
      await _sosService.resolveSosByAdmin(
        sosId: sosId,
        adminUserId: adminUserId,
      );
      _escalatedSosQueue.removeWhere((sos) => sos.id == sosId);
      notifyListeners();
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
      await _broadcastService.sendSuperAdminBroadcast(
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

  Future<bool> updateRouteAndSchedule({
    required String domainId,
    required DateTime startTime,
    required DateTime endTime,
    required String status,
    Map<String, dynamic>? routeGeojson,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _domainService.updateRouteAndSchedule(
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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sosSub?.cancel();
    _telemetrySub?.cancel();
    super.dispose();
  }
}
