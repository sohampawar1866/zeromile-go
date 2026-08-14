// lib/logic/view_models/groups_view_model.dart

import 'package:flutter/foundation.dart';
import '../../models/group_membership.dart';
import '../../models/sub_group.dart';
import '../../services/group_service.dart';

class GroupsViewModel extends ChangeNotifier {
  final GroupService _groupService;

  List<SubGroup> _domainGroups = [];
  List<GroupMembership> _userMemberships = [];
  bool _isLoading = false;
  String? _errorMessage;

  GroupsViewModel({GroupService? groupService})
      : _groupService = groupService ?? GroupService();

  List<SubGroup> get domainGroups => _domainGroups;
  List<GroupMembership> get userMemberships => _userMemberships;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get nonGeneralJoinedCount =>
      _userMemberships.where((m) => m.groupName != null && !m.groupName!.toLowerCase().contains('general')).length;

  bool get isSubGroupCapReached => nonGeneralJoinedCount >= 3;

  GroupMembership? get activeMembership =>
      _userMemberships.where((m) => m.isActive).firstOrNull ?? _userMemberships.firstOrNull;

  Future<void> loadGroups({
    required String domainId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _domainGroups = await _groupService.getDomainSubGroups(domainId);
      _userMemberships = await _groupService.getUserMemberships(domainId: domainId, userId: userId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroup({
    required String domainId,
    required String groupId,
    required String userId,
    bool setActive = false,
  }) async {
    if (isSubGroupCapReached) {
      _errorMessage = 'Limit reached: You can join at most 3 sub-groups per event domain.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final newMembership = await _groupService.joinSubGroup(
        domainId: domainId,
        groupId: groupId,
        userId: userId,
        setActive: setActive,
      );
      _userMemberships.add(newMembership);
      await loadGroups(domainId: domainId, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> switchActiveGroup({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    try {
      await _groupService.setActiveGroup(
        domainId: domainId,
        groupId: groupId,
        userId: userId,
      );
      await loadGroups(domainId: domainId, userId: userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitGroupProposal({
    required String domainId,
    required String applicantUserId,
    required String orgName,
    required String orgType,
    required int expectedCount,
    required String musterPoint,
    String? leaderNotes,
  }) async {
    try {
      await _groupService.submitGroupCreationRequest(
        domainId: domainId,
        applicantUserId: applicantUserId,
        orgName: orgName,
        orgType: orgType,
        expectedCount: expectedCount,
        musterPoint: musterPoint,
        leaderNotes: leaderNotes,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
