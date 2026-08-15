// lib/ui/features/home/components/live_route_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/route_checkpoint.dart';
import '../../../core/widgets/route_checkpoint_stepper.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class LiveRouteCard extends StatelessWidget {
  final List<RouteCheckpoint> checkpoints;
  final bool isLiveWindow;
  final VoidCallback? onNavigateToMap;

  const LiveRouteCard({
    super.key,
    required this.checkpoints,
    required this.isLiveWindow,
    this.onNavigateToMap,
  });

  static List<RouteCheckpoint> get defaultCheckpoints {
    final now = DateTime.now();
    return [
      RouteCheckpoint(
        id: 'cp-1',
        domainId: 'domain-1',
        name: 'Zero Mile Monument (Flag-off)',
        latitude: 21.1458,
        longitude: 79.0882,
        sequenceOrder: 1,
        checkpointType: CheckpointType.start,
        createdAt: now,
      ),
      RouteCheckpoint(
        id: 'cp-2',
        domainId: 'domain-1',
        name: 'Samvidhan Square Water Point',
        latitude: 21.1512,
        longitude: 79.0834,
        sequenceOrder: 2,
        checkpointType: CheckpointType.waterStation,
        createdAt: now,
      ),
      RouteCheckpoint(
        id: 'cp-3',
        domainId: 'domain-1',
        name: 'Shankar Nagar Hydration Station',
        latitude: 21.1345,
        longitude: 79.0621,
        sequenceOrder: 3,
        checkpointType: CheckpointType.waterStation,
        createdAt: now,
      ),
      RouteCheckpoint(
        id: 'cp-4',
        domainId: 'domain-1',
        name: 'Law College Square Medical Aid Tent',
        latitude: 21.1402,
        longitude: 79.0558,
        sequenceOrder: 4,
        checkpointType: CheckpointType.medicalPost,
        createdAt: now,
      ),
      RouteCheckpoint(
        id: 'cp-5',
        domainId: 'domain-1',
        name: 'Deekshabhoomi Ground Finish Line',
        latitude: 21.1278,
        longitude: 79.0712,
        sequenceOrder: 5,
        checkpointType: CheckpointType.finish,
        createdAt: now,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final list = checkpoints.isNotEmpty ? checkpoints : defaultCheckpoints;

    return ShadCard(
      title: 'Official Route Checkpoints',
      trailing: Text(
        '${list.length} Checkpoints',
        style: AppTypography.captionXs.copyWith(
          color: AppColors.mute,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RouteCheckpointStepper(
            checkpoints: list,
            completedIndex: isLiveWindow ? 1 : 0,
          ),
          if (onNavigateToMap != null) ...[
            const SizedBox(height: AppSpacing.md),
            ShadButton(
              text: 'View Full Live Route Map',
              icon: Icons.map_outlined,
              isFullWidth: true,
              size: ShadButtonSize.sm,
              variant: ShadButtonVariant.outline,
              onPressed: onNavigateToMap,
            ),
          ],
        ],
      ),
    );
  }
}
