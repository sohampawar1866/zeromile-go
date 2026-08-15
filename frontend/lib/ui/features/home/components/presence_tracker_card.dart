// lib/ui/features/home/components/presence_tracker_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/group_membership.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
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
      title: 'Event Participation Status',
      trailing: StatusBadge(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCompleted
                ? '🏁 Congratulations! You have successfully completed the rally loop. Finish certificate registered.'
                : isCheckedIn
                    ? '📍 Present at muster point${membership?.checkinTime != null ? " since ${membership!.checkinTime!.hour}:${membership!.checkinTime!.minute.toString().padLeft(2, '0')}" : ""}. Live GPS Telemetry Online.'
                    : 'ℹ️ Please tap "Check-in at Muster" when arriving at your assigned assembly point.',
            style: AppTypography.bodySm,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ShadButton(
                  text: isCheckedIn ? 'Checked In' : 'Check-In at Muster',
                  icon: isCheckedIn ? Icons.check_circle : Icons.location_on,
                  variant: isCheckedIn ? ShadButtonVariant.secondary : ShadButtonVariant.primary,
                  onPressed: isCheckedIn || isCompleted ? null : onCheckIn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ShadButton(
                  text: isCompleted ? 'Finished' : 'Mark Completed',
                  icon: Icons.flag,
                  variant: isCompleted ? ShadButtonVariant.secondary : ShadButtonVariant.outline,
                  onPressed: isCompleted ? null : onComplete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
