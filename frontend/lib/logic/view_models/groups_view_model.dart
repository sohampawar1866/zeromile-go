// lib/logic/view_models/groups_view_model.dart

import 'package:flutter/foundation.dart';
import '../../data/models/group_membership.dart';
import '../../data/models/sub_group.dart';
import '../../data/repositories/group_repository.dart';

class GroupsViewModel extends ChangeNotifier {
  final GroupRepository _groupRepository;

  List<GroupMembership> _userMemberships = [];
  List<SubGroup> _allDomainGroups = [];
  bool _isLoading = false;
  String? _errorMessage;

  GroupsViewModel({GroupRepository? groupRepository})
      : _groupRepository = groupRepository ?? GroupRepository();

  List<GroupMembership> get userMemberships => _userMemberships;
  List<SubGroup> get allDomainGroups => _allDomainGroups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadGroups({
    required String domainId,
    required String userId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _groupRepository.fetchUserMemberships(domainId: domainId, userId: userId),
        _groupRepository.fetchDomainSubGroups(domainId),
      ]);
      _userMemberships = results[0] as List<GroupMembership>;
      _allDomainGroups = results[1] as List<SubGroup>;
    } catch (e) {
      _errorMessage = e.toString();
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
      await _groupRepository.setActiveGroup(
        domainId: domainId,
        groupId: groupId,
        userId: userId,
      );
      _userMemberships = _userMemberships.map((m) {
        return m.copyWith(isActive: m.groupId == groupId);
      }).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> joinSubGroup({
    required String domainId,
    required String groupId,
    required String userId,
    bool setActive = false,
  }) async {
    try {
      final newMembership = await _groupRepository.joinSubGroup(
        domainId: domainId,
        groupId: groupId,
        userId: userId,
        setActive: setActive,
      );
      _userMemberships.add(newMembership);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
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
      await _groupRepository.submitGroupCreationRequest(
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
      return false;
    }
  }
}
