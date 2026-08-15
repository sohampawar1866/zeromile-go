// lib/ui/features/groups/my_groups_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../logic/view_models/groups_view_model.dart';
import '../../core/dialogs/group_creation_modal.dart';
import '../../core/components/shad_button.dart';
import '../../core/components/shad_card.dart';

class MyGroupsScreen extends StatefulWidget {
  final GroupsViewModel viewModel;
  final String domainId;
  final String userId;

  const MyGroupsScreen({
    super.key,
    required this.viewModel,
    required this.domainId,
    required this.userId,
  });

  @override
  State<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends State<MyGroupsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadGroups(
      domainId: widget.domainId,
      userId: widget.userId,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final memberships = widget.viewModel.userMemberships;
        final joinedGroupIds = memberships.map((m) => m.groupId).toSet();
        final joinedCount = memberships.length;
        final isMaxReached = joinedCount >= 3;
        final activeGroup = memberships.where((m) => m.isActive).firstOrNull;

        final availableGroups = widget.viewModel.domainGroups.where((g) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          final matchesName = g.name.toLowerCase().contains(q);
          final matchesType = g.orgType.toLowerCase().contains(q);
          final matchesMuster = (g.musterPoint ?? '').toLowerCase().contains(q);
          return matchesName || matchesType || matchesMuster;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: RefreshIndicator(
            color: AppColors.ink,
            backgroundColor: AppColors.surface,
            onRefresh: () => widget.viewModel.loadGroups(
              domainId: widget.domainId,
              userId: widget.userId,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                // 1. Quota & Active Contingent Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: activeGroup != null ? AppColors.liveIndicatorBg : AppColors.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                    border: Border.all(
                      color: activeGroup != null ? AppColors.successBorder : AppColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: activeGroup != null ? AppColors.success : AppColors.mute,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          activeGroup != null
                              ? 'Active: ${activeGroup.groupName} ($joinedCount/3 Joined)'
                              : 'No Active Contingent Selected ($joinedCount/3 Joined)',
                          style: AppTypography.captionXs.copyWith(
                            fontWeight: FontWeight.w600,
                            color: activeGroup != null ? AppColors.liveIndicatorText : AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        activeGroup != null ? Icons.check_circle : Icons.info_outline,
                        color: activeGroup != null ? AppColors.success : AppColors.mute,
                        size: 16,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // 2. Enrolled Sub-Groups
                ShadCard(
                  title: 'Enrolled Contingents',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.softCloud,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Text(
                      '$joinedCount/3 JOINED',
                      style: AppTypography.captionXs.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (memberships.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.hairlineSoft),
                          ),
                          child: const Text(
                            'You have not joined any squads yet. Browse available clubs below to join.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption,
                          ),
                        )
                      else
                        ...memberships.map((m) {
                          final isActive = m.isActive;

                          return GestureDetector(
                            onTap: () async {
                              final ok = await widget.viewModel.switchActiveGroup(
                                domainId: widget.domainId,
                                groupId: m.groupId,
                                userId: widget.userId,
                              );
                              if (context.mounted && ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Active contingent set to ${m.groupName}.'),
                                    backgroundColor: AppColors.ink,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.liveIndicatorBg : AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(
                                  color: isActive ? AppColors.successBorder : AppColors.hairline,
                                  width: isActive ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive ? AppColors.success : Colors.transparent,
                                      border: Border.all(
                                        color: isActive ? AppColors.success : AppColors.stone,
                                        width: 2,
                                      ),
                                    ),
                                    child: isActive
                                        ? const Icon(Icons.check, size: 12, color: AppColors.onPrimary)
                                        : null,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.groupName ?? 'Contingent Group',
                                          style: AppTypography.bodyStrong,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isActive ? 'Designated for Live SOS & Telemetry' : 'Tap to set as active contingent',
                                          style: AppTypography.captionXs.copyWith(
                                            color: isActive ? AppColors.liveIndicatorText : AppColors.mute,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (m.isLeader)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.ink,
                                        borderRadius: BorderRadius.circular(AppRadius.pill),
                                      ),
                                      child: Text(
                                        'LEADER',
                                        style: AppTypography.captionXs.copyWith(
                                          color: AppColors.onPrimary,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // 3. Discover & Join Clubs Section
                ShadCard(
                  title: 'Discover & Join Clubs',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Search clubs, colleges, squads...',
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.mute),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16, color: AppColors.mute),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Club Cards List
                      if (availableGroups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No clubs available in this domain yet.'
                                  : 'No clubs match "$_searchQuery".',
                              style: AppTypography.caption,
                            ),
                          ),
                        )
                      else
                        ...availableGroups.map((group) {
                          final isAlreadyJoined = joinedGroupIds.contains(group.id);

                          return Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: AppColors.hairlineSoft),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: AppColors.hairline),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _getOrgTypeIcon(group.orgType),
                                    color: AppColors.ink,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        group.name,
                                        style: AppTypography.bodyStrong,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Muster: ${group.musterPoint ?? "Start Point"}',
                                        style: AppTypography.caption,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                if (isAlreadyJoined)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.successBg,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                      border: Border.all(color: AppColors.successBorder),
                                    ),
                                    child: Text(
                                      'JOINED',
                                      style: AppTypography.captionXs.copyWith(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else if (isMaxReached)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.softCloud,
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: Text(
                                      'MAX (3)',
                                      style: AppTypography.captionXs.copyWith(
                                        color: AppColors.mute,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else
                                  ShadButton(
                                    text: 'Join',
                                    icon: Icons.add,
                                    size: ShadButtonSize.sm,
                                    variant: ShadButtonVariant.primary,
                                    onPressed: () async {
                                      final ok = await widget.viewModel.joinGroup(
                                        domainId: widget.domainId,
                                        groupId: group.id,
                                        userId: widget.userId,
                                        setActive: joinedCount == 0,
                                      );
                                      if (context.mounted && ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Joined ${group.name}!'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),

                const SizedBox(height: 88),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              GroupCreationModal.show(
                context,
                onSubmit: ({
                  required String orgName,
                  required String orgType,
                  required int expectedCount,
                  required String musterPoint,
                  String? leaderNotes,
                }) async {
                  final ok = await widget.viewModel.submitGroupProposal(
                    domainId: widget.domainId,
                    applicantUserId: widget.userId,
                    orgName: orgName,
                    orgType: orgType,
                    expectedCount: expectedCount,
                    musterPoint: musterPoint,
                    leaderNotes: leaderNotes,
                  );
                  if (context.mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Proposal for $orgName submitted for admin review!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              );
            },
            backgroundColor: AppColors.ink,
            foregroundColor: AppColors.onPrimary,
            elevation: 0,
            highlightElevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            ),
            icon: const Icon(Icons.group_add, size: 16),
            label: const Text(
              'CREATE CONTINGENT',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
        );
      },
    );
  }

  IconData _getOrgTypeIcon(String orgType) {
    switch (orgType.toUpperCase()) {
      case 'CYCLING_CLUB':
      case 'CYCLING':
        return Icons.directions_bike;
      case 'CORPORATE':
        return Icons.business_outlined;
      case 'COLLEGE':
      case 'UNIVERSITY':
        return Icons.school_outlined;
      case 'COMMUNITY':
        return Icons.people_outline;
      default:
        return Icons.groups_outlined;
    }
  }
}
