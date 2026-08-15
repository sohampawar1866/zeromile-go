// lib/ui/core/widgets/route_tracking_bottom_sheet.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/route_checkpoint.dart';

class RouteTrackingBottomSheet extends StatelessWidget {
  final List<RouteCheckpoint> checkpoints;
  final int activeCheckpointIndex;
  final double distanceRemainingKm;
  final String estimatedArrivalTime;
  final String nextCheckpointName;
  final VoidCallback? onToggleExpand;
  final bool isExpanded;

  const RouteTrackingBottomSheet({
    super.key,
    required this.checkpoints,
    this.activeCheckpointIndex = 1,
    this.distanceRemainingKm = 2.4,
    this.estimatedArrivalTime = '7:45 AM',
    this.nextCheckpointName = 'Water Station 2',
    this.onToggleExpand,
    this.isExpanded = false,
  });

  IconData _getCheckpointIcon(CheckpointType type) {
    switch (type) {
      case CheckpointType.start:
        return Icons.flag_outlined;
      case CheckpointType.waterStation:
        return Icons.water_drop_outlined;
      case CheckpointType.medicalPost:
        return Icons.medical_services_outlined;
      case CheckpointType.diversion:
        return Icons.alt_route_outlined;
      case CheckpointType.finish:
        return Icons.sports_score_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<RouteCheckpoint> effectiveCheckpoints = checkpoints.isNotEmpty
        ? checkpoints
        : [
            RouteCheckpoint(
              id: 'c1',
              domainId: 'cycling-domain',
              name: 'Zero Mile',
              checkpointType: CheckpointType.start,
              latitude: 21.1466,
              longitude: 79.0888,
              sequenceOrder: 1,
              createdAt: DateTime.now(),
            ),
            RouteCheckpoint(
              id: 'c2',
              domainId: 'cycling-domain',
              name: 'Water Point 1',
              checkpointType: CheckpointType.waterStation,
              latitude: 21.1520,
              longitude: 79.0950,
              sequenceOrder: 2,
              createdAt: DateTime.now(),
            ),
            RouteCheckpoint(
              id: 'c3',
              domainId: 'cycling-domain',
              name: 'Medical Aid',
              checkpointType: CheckpointType.medicalPost,
              latitude: 21.1600,
              longitude: 79.1020,
              sequenceOrder: 3,
              createdAt: DateTime.now(),
            ),
            RouteCheckpoint(
              id: 'c4',
              domainId: 'cycling-domain',
              name: 'Finish Gate',
              checkpointType: CheckpointType.finish,
              latitude: 21.1680,
              longitude: 79.1100,
              sequenceOrder: 4,
              createdAt: DateTime.now(),
            ),
          ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle Pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title & Estimated Arrival Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heading to $nextCheckpointName',
                          style: AppTypography.headingMd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'arrives today at ',
                              style: AppTypography.caption.copyWith(color: AppColors.mute),
                            ),
                            Text(
                              estimatedArrivalTime,
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              ' • ${distanceRemainingKm.toStringAsFixed(1)} km left',
                              style: AppTypography.caption.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(
                      Icons.directions_bike_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Horizontal Checkpoint Milestone Stepper
              _buildMilestoneStepper(effectiveCheckpoints),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMilestoneStepper(List<RouteCheckpoint> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = items.length;
        if (count == 0) return const SizedBox.shrink();

        return Column(
          children: [
            // Row of icon nodes with connecting lines
            Row(
              children: List.generate(count * 2 - 1, (index) {
                if (index.isOdd) {
                  // Connecting line
                  final lineIndex = index ~/ 2;
                  final isPassed = lineIndex < activeCheckpointIndex;
                  return Expanded(
                    child: Container(
                      height: 3,
                      color: isPassed ? AppColors.primary : AppColors.hairline,
                    ),
                  );
                } else {
                  // Node icon circle
                  final nodeIndex = index ~/ 2;
                  final item = items[nodeIndex];
                  final isPassed = nodeIndex <= activeCheckpointIndex;
                  final isCurrent = nodeIndex == activeCheckpointIndex;

                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isPassed ? AppColors.primary : AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPassed ? AppColors.primary : AppColors.hairline,
                        width: 2,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isPassed && nodeIndex < activeCheckpointIndex
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Icon(
                              _getCheckpointIcon(item.checkpointType),
                              size: 16,
                              color: isPassed ? Colors.white : AppColors.mute,
                            ),
                    ),
                  );
                }
              }),
            ),

            const SizedBox(height: 6),

            // Row of milestone labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: items.map((item) {
                final nodeIndex = items.indexOf(item);
                final isCurrent = nodeIndex == activeCheckpointIndex;
                return SizedBox(
                  width: (constraints.maxWidth / count).clamp(40.0, 75.0),
                  child: Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: AppTypography.captionXs.copyWith(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? AppColors.ink : AppColors.mute,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
