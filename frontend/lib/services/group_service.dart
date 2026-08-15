// lib/services/group_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sub_group.dart';
import '../models/group_membership.dart';
import '../models/group_creation_request.dart';
import '../utils/phone_utils.dart';
import 'supabase_client_service.dart';

class GroupService {
  final SupabaseClient _client;

  GroupService({SupabaseClient? client})
      : _client = client ?? SupabaseClientService.instance.client;

  /// Fetch all approved sub-groups within the active domain
  Future<List<SubGroup>> getDomainSubGroups(String domainId) async {
    final data = await _client
        .from('sub_groups')
        .select()
        .eq('domain_id', domainId)
        .eq('approval_status', 'APPROVED')
        .order('name', ascending: true);

    return (data as List).map((json) => SubGroup.fromJson(json)).toList();
  }

  /// Fetch user's enrolled memberships for the domain
  Future<List<GroupMembership>> getUserMemberships({
    required String domainId,
    required String userId,
  }) async {
    final data = await _client
        .from('group_memberships')
        .select('*, sub_groups(name)')
        .eq('domain_id', domainId)
        .eq('user_id', userId);

    return (data as List).map((json) => GroupMembership.fromJson(json)).toList();
  }

  /// Enrolls user in a sub-group (triggers will auto-check 3-subgroups limit and auto-enroll in General group)
  Future<GroupMembership> joinSubGroup({
    required String domainId,
    required String groupId,
    required String userId,
    bool setActive = false,
  }) async {
    // 1. Insert membership with is_active = false to safely pass constraints
    final inserted = await _client
        .from('group_memberships')
        .insert({
          'domain_id': domainId,
          'group_id': groupId,
          'user_id': userId,
          'is_active': false,
          'participation_status': 'NOT_CHECKED_IN',
        })
        .select('*, sub_groups(name)')
        .single();

    final membership = GroupMembership.fromJson(inserted);

    // 2. If requested to be active, atomically activate via RPC
    if (setActive) {
      await setActiveGroup(
        domainId: domainId,
        groupId: groupId,
        userId: userId,
      );
      return membership.copyWith(isActive: true);
    }

    return membership;
  }

  /// Atomic switch: marks this group as ACTIVE and all other domain groups as INACTIVE
  Future<Map<String, dynamic>> setActiveGroup({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    final response = await _client.rpc('set_active_group', params: {
      'p_domain_id': domainId,
      'p_group_id': groupId,
      'p_user_id': userId,
    });
    return response != null ? Map<String, dynamic>.from(response as Map) : {};
  }

  /// Participant Presence: 1-Tap Check-In / Mark Present at Muster
  Future<Map<String, dynamic>> checkInParticipant({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    final response = await _client.rpc('check_in_participant', params: {
      'p_domain_id': domainId,
      'p_group_id': groupId,
      'p_user_id': userId,
    });
    return response != null ? Map<String, dynamic>.from(response as Map) : {};
  }

  /// Participant Completion: 1-Tap Mark Finished / Completed Rally
  Future<Map<String, dynamic>> completeEventParticipant({
    required String domainId,
    required String groupId,
    required String userId,
  }) async {
    final response = await _client.rpc('complete_event_participant', params: {
      'p_domain_id': domainId,
      'p_group_id': groupId,
      'p_user_id': userId,
    });
    return response != null ? Map<String, dynamic>.from(response as Map) : {};
  }

  /// User submits a new group creation application
  Future<GroupCreationRequest> submitGroupCreationRequest({
    required String domainId,
    required String applicantUserId,
    required String orgName,
    required String orgType,
    required int expectedCount,
    required String musterPoint,
    String? leaderNotes,
  }) async {
    final inserted = await _client
        .from('group_creation_requests')
        .insert({
          'domain_id': domainId,
          'applicant_user_id': applicantUserId,
          'org_name': orgName,
          'org_type': orgType,
          'expected_count': expectedCount,
          'muster_point': musterPoint,
          'leader_notes': leaderNotes,
          'status': 'PENDING',
        })
        .select()
        .single();

    return GroupCreationRequest.fromJson(inserted);
  }

  /// SuperAdmin Console: Fetch pending group applications
  Future<List<GroupCreationRequest>> getPendingGroupRequests(String domainId) async {
    final data = await _client
        .from('group_creation_requests')
        .select('*, users(full_name, phone_number)')
        .eq('domain_id', domainId)
        .eq('status', 'PENDING')
        .order('created_at', ascending: false);

    return (data as List).map((json) => GroupCreationRequest.fromJson(json)).toList();
  }

  /// SuperAdmin Console: Review & Approve/Reject group application
  Future<void> reviewGroupRequest({
    required String requestId,
    required String reviewerUserId,
    required bool approve,
  }) async {
    await _client.from('group_creation_requests').update({
      'status': approve ? 'APPROVED' : 'REJECTED',
      'reviewed_by': reviewerUserId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }

  /// Group Leader Hub: Direct add member by mobile phone number
  Future<Map<String, dynamic>> leaderDirectAddMember({
    required String domainId,
    required String groupId,
    required String leaderUserId,
    required String memberPhone,
    required String memberName,
  }) async {
    final cleanPhone = PhoneUtils.toDbFormat(memberPhone);
    final response = await _client.rpc('leader_direct_add_member', params: {
      'p_domain_id': domainId,
      'p_group_id': groupId,
      'p_leader_user_id': leaderUserId,
      'p_member_phone': cleanPhone,
      'p_member_name': memberName,
    });
    return response != null ? Map<String, dynamic>.from(response as Map) : {};
  }

  /// Group Leader Hub: Fetch team roster & muster check-in stats
  Future<List<GroupMembership>> getGroupRoster({
    required String domainId,
    required String groupId,
  }) async {
    final data = await _client
        .from('group_memberships')
        .select('*, users(full_name, phone_number, avatar_url, emergency_contact)')
        .eq('domain_id', domainId)
        .eq('group_id', groupId)
        .order('joined_at', ascending: true);

    return (data as List).map((json) => GroupMembership.fromJson(json)).toList();
  }
}
