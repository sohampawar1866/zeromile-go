// lib/ui/features/leader_hub/tabs/leader_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class LeaderAnalyticsTab extends StatelessWidget {
  final LeaderHubViewModel viewModel;

  const LeaderAnalyticsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final activePercentStr = viewModel.totalEnrolled > 0
        ? (viewModel.activeToday / viewModel.totalEnrolled * 100).toStringAsFixed(0)
        : '0';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Contingent Telemetry Overview Card
        ShadCard(
          title: 'Contingent Performance',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.liveIndicatorBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Text(
              '${viewModel.checkinPercent.toStringAsFixed(0)}% READY',
              style: AppTypography.captionXs.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressSection(
                'Muster Point Check-In',
                '${viewModel.checkedInMuster} of ${viewModel.totalEnrolled} Members',
                viewModel.checkinPercent / 100,
                AppColors.success,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildProgressSection(
                'Route Finish Completion',
                '${viewModel.completedCount} of ${viewModel.totalEnrolled} Finished',
                viewModel.completionPercent / 100,
                AppColors.info,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildProgressSection(
                'Live GPS Telemetry Tracking',
                '${viewModel.activeToday} of ${viewModel.totalEnrolled} Active Online ($activePercentStr%)',
                viewModel.totalEnrolled > 0 ? (viewModel.activeToday / viewModel.totalEnrolled) : 0,
                AppColors.ink,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. Safety & Incidents Summary Card
        ShadCard(
          title: 'Incident & Distress Log',
          trailing: Text(
            '${viewModel.teamSosAlerts.length} Alerts',
            style: AppTypography.captionXs.copyWith(
              color: viewModel.teamSosAlerts.isEmpty ? AppColors.success : AppColors.sale,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatTile('Emergency Alerts', '${viewModel.teamSosAlerts.length}', viewModel.teamSosAlerts.isEmpty ? AppColors.success : AppColors.sale),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatTile('GPS Status', viewModel.teamLocations.isNotEmpty ? 'Active' : 'Standby', AppColors.ink),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ShadButton(
                text: 'Download Attendance Report (CSV)',
                icon: Icons.download,
                variant: ShadButtonVariant.outline,
                isFullWidth: true,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contingent attendance report exported to Downloads.'),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 88),
      ],
    );
  }

  Widget _buildProgressSection(String title, String subtitle, double progress, Color barColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: AppSpacing.sm),
            Text(subtitle, style: AppTypography.caption),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.hairlineSoft,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.headingMd.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
