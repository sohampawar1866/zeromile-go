// lib/ui/features/home/components/live_route_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/route_checkpoint.dart';
import '../../../core/widgets/density_cluster_map_view.dart';
import '../../../core/widgets/route_checkpoint_stepper.dart';
import '../../../core/components/shad_card.dart';

class LiveRouteCard extends StatelessWidget {
  final List<RouteCheckpoint> checkpoints;
  final bool isLiveWindow;

  const LiveRouteCard({
    super.key,
    required this.checkpoints,
    required this.isLiveWindow,
  });

  @override
  Widget build(BuildContext context) {
    return ShadCard(
      title: isLiveWindow ? 'Live Rally Route' : 'Route Preview',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLiveWindow ? Icons.sensors : Icons.map_outlined,
            color: isLiveWindow ? AppColors.success : AppColors.mute,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isLiveWindow ? 'Live GPS' : 'Static',
            style: AppTypography.captionXs.copyWith(
              color: isLiveWindow ? AppColors.success : AppColors.mute,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DensityClusterMapView(
            title: isLiveWindow ? 'Nagpur Loop (Live Telemetry Online)' : 'Nagpur Loop (Static Geometry)',
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Official Route Checkpoints',
            style: AppTypography.headingMd,
          ),
          const SizedBox(height: AppSpacing.sm),
          RouteCheckpointStepper(
            checkpoints: checkpoints,
            completedIndex: isLiveWindow ? 1 : 0,
          ),
        ],
      ),
    );
  }
}
