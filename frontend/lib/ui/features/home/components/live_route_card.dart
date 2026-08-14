// lib/ui/features/home/components/live_route_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../data/models/route_checkpoint.dart';
import '../../../core/widgets/density_cluster_map_view.dart';
import '../../../core/widgets/route_checkpoint_stepper.dart';

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
    return Card(
      child: Padding(
        padding: AppSpacing.edgeInsetsCard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLiveWindow ? Icons.map_outlined : Icons.preview,
                  color: AppColors.ink,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isLiveWindow ? 'Interactive Live Rally Route' : 'Published Static Route Preview',
                    style: AppTypography.headingMd,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
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
      ),
    );
  }
}
