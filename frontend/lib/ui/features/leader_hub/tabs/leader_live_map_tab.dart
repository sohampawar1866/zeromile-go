// lib/ui/features/leader_hub/tabs/leader_live_map_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../core/widgets/density_cluster_map_view.dart';
import '../../../core/components/shad_card.dart';

class LeaderLiveMapTab extends StatefulWidget {
  final LeaderHubViewModel viewModel;

  const LeaderLiveMapTab({super.key, required this.viewModel});

  @override
  State<LeaderLiveMapTab> createState() => _LeaderLiveMapTabState();
}

class _LeaderLiveMapTabState extends State<LeaderLiveMapTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewModel = widget.viewModel;
    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        ShadCard(
          title: 'Live Team GPS Tracking',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sensors, size: 14, color: AppColors.success),
              const SizedBox(width: 4),
              Text(
                'Contingent',
                style: AppTypography.captionXs.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          child: DensityClusterMapView(
            title: viewModel.groupName.isNotEmpty
                ? '${viewModel.groupName} Telemetry'
                : 'Contingent Telemetry',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ShadCard(
          title: 'Telemetry & Attendance Stats',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Contingent Size', '${viewModel.totalEnrolled} Enrolled'),
              _buildStatRow('Check-in Attendance Rate', '${viewModel.checkinPercent.toStringAsFixed(1)}% Checked-in'),
              _buildStatRow('Route Completion Rate', '${viewModel.completionPercent.toStringAsFixed(1)}% Finished'),
              _buildStatRow('Active Location Streams', viewModel.teamLocations.isNotEmpty ? '${viewModel.teamLocations.length} Active' : 'Standby / Idle'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
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
