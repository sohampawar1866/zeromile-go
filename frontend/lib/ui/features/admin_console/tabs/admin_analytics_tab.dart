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
                _buildStatItem('Total General Participants', '1,248 Citizens'),
                _buildStatItem('Approved Sub-Groups', '${viewModel.subGroups.length} Contingents'),
                _buildStatItem('Active Sub-Group Members', '1,020 Riders (81.7%)'),
                _buildStatItem('General-Only Participants', '228 Riders (18.3%)'),
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
                _buildStatItem('Total SOS Triggered Today', '${viewModel.escalatedSosQueue.length + 3}'),
                _buildStatItem('Average Resolution Time', '4.2 Min (Target: <5m)'),
                _buildStatItem('Active Ambulance Dispatches', '${viewModel.escalatedSosQueue.length} Active'),
                _buildStatItem('Muster Check-In Compliance', '94.2% Present'),
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
                _buildBreakdownBar('Colleges / Univs (VNIT, RCOEM)', 0.42, '42% (524 pax)', AppColors.ink),
                _buildBreakdownBar('Corporate / Sports Clubs', 0.32, '32% (400 pax)', AppColors.info),
                _buildBreakdownBar('NGOs & Civil Society Orgs', 0.26, '26% (324 pax)', AppColors.accentTeal),
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
