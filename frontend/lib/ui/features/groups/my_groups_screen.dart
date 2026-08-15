// lib/ui/features/groups/my_groups_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../logic/view_models/groups_view_model.dart';
import '../../core/widgets/fluid_tap_scale.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/dialogs/group_creation_modal.dart';

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
  @override
  void initState() {
    super.initState();
    widget.viewModel.loadGroups(
      domainId: widget.domainId,
      userId: widget.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final memberships = widget.viewModel.userMemberships;
        final joinedCount = memberships.length;
        final isMaxReached = joinedCount >= 3;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: ListView(
            padding: AppSpacing.edgeInsetsScreen,
            children: [
          // Quota & Rules Card
          ShadCard(
            title: 'Contingent Membership Quota',
            trailing: StatusBadge(
              label: '$joinedCount/3 JOINED',
              type: isMaxReached ? StatusBadgeType.warning : StatusBadgeType.success,
            ),
            child: const Text(
              'You may join up to 3 sub-groups per event, but you can only designate ONE active contingent for live telemetry and SOS triage routing.',
              style: AppTypography.bodySm,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Enrolled Groups List
          ShadCard(
            title: 'Your Enrolled Sub-Groups',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (memberships.isEmpty)
                  const Text('You have not joined any sub-groups yet.', style: AppTypography.caption)
                else
                  ...memberships.map((m) {
                    final isActive = m.isActive;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: AppSpacing.edgeInsetsCard,
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                        border: Border.all(
                          color: isActive ? AppColors.ink : AppColors.hairlineSoft,
                          width: isActive ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final ok = await widget.viewModel.switchActiveGroup(
                                domainId: widget.domainId,
                                groupId: m.groupId,
                                userId: widget.userId,
                              );
                              if (context.mounted && ok) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Active contingent updated.'),
                                    backgroundColor: AppColors.ink,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              margin: const EdgeInsets.only(right: AppSpacing.sm),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive ? AppColors.ink : AppColors.hairline,
                                  width: isActive ? 5 : 1.5,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.groupName ?? 'Contingent Group',
                                  style: AppTypography.bodyStrong,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Participation Status: ${m.participationStatus.name.toUpperCase()}',
                                  style: AppTypography.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (m.isLeader)
                            const Padding(
                              padding: EdgeInsets.only(left: AppSpacing.xs),
                              child: StatusBadge(label: 'LEADER', type: StatusBadgeType.warning),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Propose New Sub-Group Action
          ShadButton(
            text: 'Propose New Contingent Sub-Group',
            icon: Icons.add_business,
            isFullWidth: true,
            variant: ShadButtonVariant.primary,
            onPressed: () {
              GroupCreationModal.show(
                context,
                onSubmit: ({
                  required orgName,
                  required orgType,
                  required expectedCount,
                  required musterPoint,
                  leaderNotes,
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
                      const SnackBar(
                        content: Text('Proposal submitted! SuperAdmins will review your application.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
        );
      },
    );
  }
}
