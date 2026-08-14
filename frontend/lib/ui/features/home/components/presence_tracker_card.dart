// lib/ui/features/home/components/presence_tracker_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
import '../../../core/widgets/status_badge.dart';

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
                  child: Text(
                    'Event Participation Status',
                    style: AppTypography.headingMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                StatusBadge(
                  label: isCompleted
                      ? 'COMPLETED'
                      : isCheckedIn
                          ? 'CHECKED IN'
                          : 'NOT CHECKED IN',
                  type: isCompleted
                      ? StatusBadgeType.primary
                      : isCheckedIn
                          ? StatusBadgeType.success
                          : StatusBadgeType.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isCompleted
                  ? '🏁 Congratulations! You have successfully completed the rally loop. Finish certificate registered.'
                  : isCheckedIn
                      ? '📍 Present at muster point since ${membership?.checkinTime != null ? "${membership!.checkinTime!.hour}:${membership!.checkinTime!.minute.toString().padLeft(2, '0')}" : "06:15 AM"}. Live GPS Telemetry Online.'
                      : 'ℹ️ Please tap "Check-in at Muster" when arriving at your assigned assembly point.',
              style: AppTypography.bodySm,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FluidTapScale(
                    onTap: isCheckedIn || isCompleted ? () {} : onCheckIn,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: isCheckedIn ? AppColors.successBg : AppColors.ink,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                        border: isCheckedIn ? Border.all(color: AppColors.successBorder) : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCheckedIn ? Icons.check_circle : Icons.location_on,
                            size: 15,
                            color: isCheckedIn ? AppColors.success : AppColors.onPrimary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isCheckedIn ? 'Checked In' : 'Check-In at Muster',
                            style: AppTypography.buttonSm.copyWith(
                              color: isCheckedIn ? AppColors.success : AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FluidTapScale(
                    onTap: isCompleted ? () {} : onComplete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.softCloud : AppColors.canvas,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                        border: Border.all(
                          color: isCompleted ? AppColors.hairlineSoft : AppColors.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flag,
                            size: 15,
                            color: isCompleted ? AppColors.success : AppColors.ink,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isCompleted ? 'Finished' : 'Mark Completed',
                            style: AppTypography.buttonSm.copyWith(
                              color: isCompleted ? AppColors.success : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
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
