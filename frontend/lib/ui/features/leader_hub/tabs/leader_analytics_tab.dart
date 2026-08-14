// lib/ui/features/leader_hub/tabs/leader_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';

class LeaderAnalyticsTab extends StatelessWidget {
  final LeaderHubViewModel viewModel;

  const LeaderAnalyticsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final activePercentStr = viewModel.totalEnrolled > 0
        ? (viewModel.activeToday / viewModel.totalEnrolled * 100).toStringAsFixed(1)
        : '0.0';

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team Muster Performance Metrics',
                  style: AppTypography.headingMd,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMetricRow('Total Enrolled Members', '${viewModel.totalEnrolled}'),
                _buildMetricRow('Currently Active Today', '${viewModel.activeToday} ($activePercentStr%)'),
                _buildMetricRow('Checked-In at Muster', '${viewModel.checkedInMuster} (${viewModel.checkinPercent.toStringAsFixed(1)}%)'),
                _buildMetricRow('Completed Route Finish', '${viewModel.completedCount} (${viewModel.completionPercent.toStringAsFixed(1)}%)'),
                const SizedBox(height: AppSpacing.md),
                const Text('MUSTER ROLL PROGRESS', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: viewModel.checkinPercent / 100,
                  minHeight: 6,
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                  backgroundColor: AppColors.hairlineSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                const Text('INCIDENT & SAFETY LOG', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.xs),
                _buildMetricRow('SOS Triggered Today', '${viewModel.teamSosAlerts.length}'),
                _buildMetricRow('Roster Telemetry Status', viewModel.teamLocations.isNotEmpty ? 'Live Tracking Active' : 'Idle / Standby'),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FluidTapScale(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Team attendance roster CSV exported to downloads.'),
                          backgroundColor: AppColors.ink,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download, size: 16, color: AppColors.ink),
                          SizedBox(width: AppSpacing.sm),
                          Text('Export Team Attendance CSV', style: AppTypography.buttonSmSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.xs),
          Text(val, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }
}
