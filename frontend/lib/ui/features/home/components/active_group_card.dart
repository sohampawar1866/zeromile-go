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
  final VoidCallback onManageGroups;

  const ActiveGroupCard({
    super.key,
    required this.membership,
    required this.onManageGroups,
  });

  @override
  Widget build(BuildContext context) {
    final isEnrolled = membership != null;
    final groupName = membership?.groupName ?? 'General Rally Participant';
    final isLeader = membership?.isLeader ?? false;

    return ShadCard(
      title: 'Active Sub-Group',
      trailing: StatusBadge(
        label: !isEnrolled ? 'General' : (isLeader ? 'Leader' : 'Member'),
        type: !isEnrolled ? StatusBadgeType.muted : (isLeader ? StatusBadgeType.warning : StatusBadgeType.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppSpacing.edgeInsetsCard,
            decoration: BoxDecoration(
              color: AppColors.softCloud,
              borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: AppTypography.bodyStrong,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isEnrolled
                      ? 'Muster Point: Samvidhan Square • Telemetry Online'
                      : 'Muster Point: Zero Mile Monument (Start Point) • General Route',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 14, color: AppColors.ink),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        isEnrolled
                            ? 'SOS routes to: Contingent Leader'
                            : 'SOS routes to: SuperAdmin Command Center',
                        style: AppTypography.captionXs.copyWith(
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
          ShadButton(
            text: 'Browse & Switch Contingent',
            icon: Icons.groups_outlined,
            isFullWidth: true,
            size: ShadButtonSize.md,
            variant: ShadButtonVariant.outline,
            onPressed: onManageGroups,
          ),
        ],
      ),
    );
  }
}
