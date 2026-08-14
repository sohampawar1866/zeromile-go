// lib/ui/core/widgets/route_checkpoint_stepper.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../data/models/route_checkpoint.dart';

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
    final list = checkpoints.isNotEmpty
        ? checkpoints
        : [
            RouteCheckpoint(
              id: 'cp-1',
              domainId: 'domain-1',
              name: 'Zero Mile Monument (Start Flag-off)',
              sequenceOrder: 1,
              checkpointType: CheckpointType.start,
              latitude: 21.1458,
              longitude: 79.0882,
              createdAt: DateTime.now(),
            ),
            RouteCheckpoint(
              id: 'cp-2',
              domainId: 'domain-1',
              name: 'Samvidhan Square (Water Point #1)',
              sequenceOrder: 2,
              checkpointType: CheckpointType.waterStation,
              latitude: 21.1500,
              longitude: 79.0800,
              createdAt: DateTime.now(),
            ),
            RouteCheckpoint(
              id: 'cp-3',
              domainId: 'domain-1',
              name: 'Law College Sq (Medical Aid Unit #1)',
              sequenceOrder: 3,
              checkpointType: CheckpointType.medicalPost,
              latitude: 21.1400,
              longitude: 79.0600,
              createdAt: DateTime.now(),
            ),
            RouteCheckpoint(
              id: 'cp-4',
              domainId: 'domain-1',
              name: 'Deekshabhoomi Ground (Rally Finish & Pass)',
              sequenceOrder: 4,
              checkpointType: CheckpointType.finish,
              latitude: 21.1275,
              longitude: 79.0667,
              createdAt: DateTime.now(),
            ),
          ];

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
