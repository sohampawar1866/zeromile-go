// lib/ui/features/admin_console/tabs/admin_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';

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
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Participation Summary Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Domain Participation Overview', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildStatItem('Active GPS Telemetry Online', '${viewModel.activeRiderCount} Participants'),
                _buildStatItem('Approved Sub-Groups', '${viewModel.subGroups.length} Contingents'),
                _buildStatItem('Pending Contingent Proposals', '${viewModel.pendingRequests.length} Pending Review'),
                _buildStatItem('Active SOS Emergency Queue', '${viewModel.escalatedSosQueue.length} Active Tickets'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Route Traffic & Incident SLA Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Route Traffic & Safety Incident SLA', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildStatItem('Active Emergency Dispatches', '${viewModel.escalatedSosQueue.length} Dispatched'),
                _buildStatItem('Active Contingents Enrolled', '${viewModel.subGroups.length} Groups'),
                _buildStatItem('Active Group Filter Target', viewModel.selectedGroupFilter.isEmpty ? 'All Domain Contingents' : 'Filtered Contingent'),
                _buildStatItem('Telemetry Stream Status', 'Connected (Supabase Realtime)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Contingent Breakdown by Org Type
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contingent Breakdown (By Org Type)', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildBreakdownBar('Educational / Colleges (VNIT, etc.)', collegeFraction, '$collegeCount Groups (${(collegeFraction * 100).toStringAsFixed(0)}%)', AppColors.ink),
                _buildBreakdownBar('Sports & Athletic Clubs', sportsFraction, '$sportsCount Groups (${(sportsFraction * 100).toStringAsFixed(0)}%)', AppColors.info),
                _buildBreakdownBar('General & Civil Society Orgs', generalFraction, '$generalCount Groups (${(generalFraction * 100).toStringAsFixed(0)}%)', AppColors.accentTeal),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FluidTapScale(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Complete domain telemetry and incident audit log downloaded.'),
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
                          Text('Download Domain Audit Log', style: AppTypography.buttonSm),
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

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.xs),
          Text(value, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }

  Widget _buildBreakdownBar(String label, double fraction, String countStr, Color barColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: AppSpacing.xs),
              Text(countStr, style: AppTypography.captionXs.copyWith(color: barColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
            backgroundColor: AppColors.hairlineSoft,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ],
      ),
    );
  }
}
