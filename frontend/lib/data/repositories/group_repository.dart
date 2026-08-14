// lib/data/repositories/group_repository.dart

import '../../models/sub_group.dart';
import '../../models/group_membership.dart';
import '../../models/group_creation_request.dart';
import '../../services/group_service.dart';

class GroupRepository {
  final GroupService _groupService;

  GroupRepository({GroupService? groupService})
      : _groupService = groupService ?? GroupService();

  Future<List<SubGroup>> fetchDomainSubGroups(String domainId) async {
    return _groupService.getDomainSubGroups(domainId);
  }

  Future<List<GroupMembership>> fetchUserMemberships({
    required String domainId,
    required String userId,
  }) async {
    return _groupService.getUserMemberships(domainId: domainId, userId: userId);
  }

  Future<GroupMembership> joinSubGroup({
    required String domainId,
    required String groupId,
    required String userId,
    bool setActive = false,
  }) async {
    return _groupService.joinSubGroup(
      domainId: domainId,
      groupId: groupId,
      userId: userId,
      setActive: setActive,
    );
  }

  Future<void> setActiveGroup({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    await _groupService.setActiveGroup(
      domainId: domainId,
      groupId: groupId,
      userId: userId,
    );
  }

  Future<void> checkInParticipant({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    await _groupService.checkInParticipant(
      domainId: domainId,
      groupId: groupId,
      userId: userId,
    );
  }

  Future<void> completeEventParticipant({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    await _groupService.completeEventParticipant(
      domainId: domainId,
      groupId: groupId,
      userId: userId,
    );
  }

  Future<GroupCreationRequest> submitGroupCreationRequest({
    required String domainId,
    required String applicantUserId,
    required String orgName,
    required String orgType,
    required int expectedCount,
    required String musterPoint,
    String? leaderNotes,
  }) async {
    return _groupService.submitGroupCreationRequest(
      domainId: domainId,
      applicantUserId: applicantUserId,
      orgName: orgName,
      orgType: orgType,
      expectedCount: expectedCount,
      musterPoint: musterPoint,
      leaderNotes: leaderNotes,
    );
  }

  Future<List<GroupCreationRequest>> fetchPendingGroupRequests(String domainId) async {
    return _groupService.getPendingGroupRequests(domainId);
  }

  Future<void> reviewGroupRequest({
    required String requestId,
    required String reviewerUserId,
    required bool approve,
  }) async {
    await _groupService.reviewGroupRequest(
      requestId: requestId,
      reviewerUserId: reviewerUserId,
      approve: approve,
    );
  }

  Future<void> leaderDirectAddMember({
    required String domainId,
    required String groupId,
    required String leaderUserId,
    required String memberPhone,
    required String memberName,
  }) async {
    await _groupService.leaderDirectAddMember(
      domainId: domainId,
      groupId: groupId,
      leaderUserId: leaderUserId,
      memberPhone: memberPhone,
      memberName: memberName,
    );
  }

  Future<List<GroupMembership>> fetchGroupRoster({
    required String domainId,
    required String groupId,
  }) async {
    return _groupService.getGroupRoster(domainId: domainId, groupId: groupId);
  }
}
