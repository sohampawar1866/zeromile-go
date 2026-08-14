// lib/ui/features/leader_hub/tabs/leader_live_map_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../core/widgets/density_cluster_map_view.dart';

class LeaderLiveMapTab extends StatelessWidget {
  final LeaderHubViewModel viewModel;

  const LeaderLiveMapTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        Card(
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
                        'Live Team GPS & Density Shading',
                        style: AppTypography.headingMd,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.sensors, size: 14, color: AppColors.success),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Contingent Only',
                          style: AppTypography.captionXs.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DensityClusterMapView(
                  title: viewModel.groupName.isNotEmpty
                      ? '${viewModel.groupName} Telemetry'
                      : 'Contingent Telemetry',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Live Contingent Telemetry Stats', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildStatRow('Contingent Size', '${viewModel.totalEnrolled} Enrolled'),
                _buildStatRow('Check-in Attendance Rate', '${viewModel.checkinPercent.toStringAsFixed(1)}% Checked-in'),
                _buildStatRow('Route Completion Rate', '${viewModel.completionPercent.toStringAsFixed(1)}% Finished'),
                _buildStatRow('Active Location Streams', viewModel.teamLocations.isNotEmpty ? '${viewModel.teamLocations.length} Active' : 'Standby / Idle'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.bodySm),
          const SizedBox(height: 3),
          Text(val, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }
}
