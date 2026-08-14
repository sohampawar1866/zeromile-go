// lib/ui/features/home/components/active_group_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../core/widgets/status_badge.dart';

class ActiveGroupCard extends StatelessWidget {
  final GroupMembership? membership;
  final VoidCallback onSwitchGroup;
  final VoidCallback onProposeGroup;

  const ActiveGroupCard({
    super.key,
    required this.membership,
    required this.onSwitchGroup,
    required this.onProposeGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isEnrolled = membership != null;
    final groupName = membership?.groupName ?? 'General Rally Participant';
    final isLeader = membership?.isLeader ?? false;

    return Card(
      child: Padding(
        padding: AppSpacing.edgeInsetsCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.groups_outlined, color: AppColors.ink, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Your Active Sub-Group',
                          style: AppTypography.headingMd,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: !isEnrolled ? 'GENERAL' : (isLeader ? 'LEADER' : 'MEMBER'),
                  type: !isEnrolled ? StatusBadgeType.muted : (isLeader ? StatusBadgeType.warning : StatusBadgeType.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: AppSpacing.edgeInsetsCard,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                border: Border.all(color: AppColors.hairlineSoft),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: AppTypography.headingMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    isEnrolled
                        ? 'Muster Point: Samvidhan Square • Active Telemetry Linked'
                        : 'Muster Point: Zero Mile Monument (Start Flag-off) • General Route',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: AppColors.ink),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          isEnrolled
                              ? 'SOS routes to: Assigned Contingent Leader'
                              : 'SOS routes to: SuperAdmin Command Center',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 16, color: AppColors.ink),
                    label: Text(
                      'Change Group',
                      style: AppTypography.buttonSm.copyWith(color: AppColors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onSwitchGroup,
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.ink),
                    label: Text(
                      'Propose Group',
                      style: AppTypography.buttonSm.copyWith(color: AppColors.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onProposeGroup,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
