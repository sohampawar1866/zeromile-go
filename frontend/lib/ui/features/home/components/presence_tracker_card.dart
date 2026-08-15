// lib/ui/features/home/components/presence_tracker_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class PresenceTrackerCard extends StatelessWidget {
  final GroupMembership? membership;
  final bool isLiveWindow;
  final VoidCallback onCheckIn;
  final VoidCallback onComplete;

  const PresenceTrackerCard({
    super.key,
    required this.membership,
    required this.isLiveWindow,
    required this.onCheckIn,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final status = membership?.participationStatus ?? ParticipationStatus.notCheckedIn;
    final isCheckedIn = status == ParticipationStatus.checkedIn;
    final isCompleted = status == ParticipationStatus.completed;

    return ShadCard(
      title: 'Event Participation',
      trailing: StatusBadge(
        label: isCompleted
            ? 'Completed'
            : isCheckedIn
                ? 'Checked In'
                : 'Not Checked In',
        type: isCompleted
            ? StatusBadgeType.primary
            : isCheckedIn
                ? StatusBadgeType.success
                : StatusBadgeType.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isCompleted
                    ? Icons.military_tech_outlined
                    : isCheckedIn
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                color: isCompleted
                    ? AppColors.ink
                    : isCheckedIn
                        ? AppColors.success
                        : AppColors.mute,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isCompleted
                      ? 'Congratulations! You have completed the rally loop. Finish certificate recorded.'
                      : isCheckedIn
                          ? 'Present at assembly point${membership?.checkinTime != null ? " since ${membership!.checkinTime!.hour.toString().padLeft(2, '0')}:${membership!.checkinTime!.minute.toString().padLeft(2, '0')}" : ""}. Live GPS tracking active.'
                          : 'Please tap "Check In Now" upon arriving at your designated meeting point.',
                  style: AppTypography.bodySm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Adaptive, stateful action button (prevents 2-button horizontal collision)
          if (!isCheckedIn && !isCompleted)
            ShadButton(
              text: 'Check In Now',
              icon: Icons.location_on_outlined,
              size: ShadButtonSize.md,
              isFullWidth: true,
              variant: ShadButtonVariant.primary,
              onPressed: onCheckIn,
            )

          else if (isCheckedIn)
            Row(
              children: [
                const Expanded(
                  child: ShadButton(
                    text: 'Checked In',
                    icon: Icons.check,
                    size: ShadButtonSize.sm,
                    variant: ShadButtonVariant.secondary,
                    onPressed: null,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: ShadButton(
                    text: 'Finish Rally',
                    icon: Icons.flag_outlined,
                    size: ShadButtonSize.sm,
                    variant: ShadButtonVariant.primary,
                    onPressed: onComplete,
                  ),
                ),
              ],
            )
          else
            const ShadButton(
              text: 'Rally Completed',
              icon: Icons.check_circle_outline,
              size: ShadButtonSize.md,
              isFullWidth: true,
              variant: ShadButtonVariant.secondary,
              onPressed: null,
            ),
        ],
      ),
    );
  }
}
