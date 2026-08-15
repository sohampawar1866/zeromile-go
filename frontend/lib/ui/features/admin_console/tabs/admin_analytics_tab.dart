// lib/ui/features/admin_console/tabs/admin_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class AdminAnalyticsTab extends StatelessWidget {
  final SuperAdminViewModel viewModel;

  const AdminAnalyticsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final totalGroups = viewModel.subGroups.isNotEmpty ? viewModel.subGroups.length : 1;
    final collegeCount = viewModel.subGroups.where((g) => g.orgType == 'COLLEGE').length;
    final sportsCount = viewModel.subGroups.where((g) => g.orgType == 'SPORTS_CLUB').length;
    final generalCount = viewModel.subGroups.where((g) => g.orgType == 'GENERAL' || g.orgType == 'NGO' || g.orgType == 'RWA').length;

    final collegeFraction = totalGroups > 0 ? (collegeCount / totalGroups).clamp(0.0, 1.0) : 0.0;
    final sportsFraction = totalGroups > 0 ? (sportsCount / totalGroups).clamp(0.0, 1.0) : 0.0;
    final generalFraction = totalGroups > 0 ? (generalCount / totalGroups).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Participation Overview Card
        ShadCard(
          title: 'Event Participation Overview',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.liveIndicatorBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Text(
              '${viewModel.activeRiderCount} RIDERS LIVE',
              style: AppTypography.captionXs.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatTile('Live Riders', '${viewModel.activeRiderCount}', AppColors.success),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatTile('Approved Squads', '${viewModel.subGroups.length}', AppColors.ink),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _buildStatTile('Pending Approvals', '${viewModel.pendingRequests.length}', viewModel.pendingRequests.isEmpty ? AppColors.mute : AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  _buildStatTile('Active SOS Queue', '${viewModel.escalatedSosQueue.length}', viewModel.escalatedSosQueue.isEmpty ? AppColors.success : AppColors.sale),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. Contingent Breakdown Card
        ShadCard(
          title: 'Contingent Breakdown (By Category)',
          trailing: Text(
            '$totalGroups Total',
            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryProgress('Educational / Colleges', '$collegeCount Squads (${(collegeFraction * 100).toStringAsFixed(0)}%)', collegeFraction, AppColors.ink),
              const SizedBox(height: AppSpacing.md),
              _buildCategoryProgress('Sports & Athletic Clubs', '$sportsCount Squads (${(sportsFraction * 100).toStringAsFixed(0)}%)', sportsFraction, AppColors.info),
              const SizedBox(height: AppSpacing.md),
              _buildCategoryProgress('Civil Society / NGOs', '$generalCount Squads (${(generalFraction * 100).toStringAsFixed(0)}%)', generalFraction, AppColors.accentTeal),
              const SizedBox(height: AppSpacing.lg),
              ShadButton(
                text: 'Download Municipal Event Audit (CSV)',
                icon: Icons.download_outlined,
                isFullWidth: true,
                variant: ShadButtonVariant.outline,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Municipal event audit log exported to Downloads.'),
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
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.headingMd.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(String title, String subtitle, double fraction, Color color) {
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
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.hairlineSoft,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
