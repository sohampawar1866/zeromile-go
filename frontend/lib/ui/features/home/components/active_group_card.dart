// lib/ui/features/home/components/active_group_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

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

    return ShadCard(
      title: 'Your Active Sub-Group',
      trailing: StatusBadge(
        label: !isEnrolled ? 'GENERAL' : (isLeader ? 'LEADER' : 'MEMBER'),
        type: !isEnrolled ? StatusBadgeType.muted : (isLeader ? StatusBadgeType.warning : StatusBadgeType.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ShadButton(
                  text: 'Change Group',
                  icon: Icons.swap_horiz,
                  variant: ShadButtonVariant.outline,
                  onPressed: onSwitchGroup,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShadButton(
                  text: 'Propose Group',
                  icon: Icons.add_circle_outline,
                  variant: ShadButtonVariant.secondary,
                  onPressed: onProposeGroup,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
