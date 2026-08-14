// lib/ui/core/widgets/route_checkpoint_stepper.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/route_checkpoint.dart';

class RouteCheckpointStepper extends StatelessWidget {
  final List<RouteCheckpoint> checkpoints;
  final int completedIndex;

  const RouteCheckpointStepper({
    super.key,
    required this.checkpoints,
    this.completedIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (checkpoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: const Text(
          'No checkpoints published yet for this route.',
          style: AppTypography.caption,
        ),
      );
    }

    final list = checkpoints;

    return Column(
      children: List.generate(list.length, (idx) {
        final cp = list[idx];
        final isPassed = idx <= completedIndex;
        final isLast = idx == list.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isPassed ? AppColors.ink : AppColors.canvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPassed ? AppColors.ink : AppColors.hairline,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: isPassed
                        ? const Icon(Icons.check, size: 12, color: AppColors.onPrimary)
                        : Text(
                            '${cp.sequenceOrder}',
                            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
                          ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 28,
                    color: isPassed ? AppColors.ink : AppColors.hairlineSoft,
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(_getIcon(cp.checkpointType), size: 14, color: isPassed ? AppColors.ink : AppColors.mute),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        cp.name,
                        style: AppTypography.bodySm.copyWith(
                          fontWeight: isPassed ? FontWeight.w600 : FontWeight.w400,
                          color: isPassed ? AppColors.ink : AppColors.mute,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _getIcon(CheckpointType cat) {
    switch (cat) {
      case CheckpointType.start:
        return Icons.flag;
      case CheckpointType.waterStation:
        return Icons.local_drink;
      case CheckpointType.medicalPost:
        return Icons.local_hospital;
      case CheckpointType.diversion:
        return Icons.alt_route;
      case CheckpointType.finish:
        return Icons.sports_score;
    }
  }
}
