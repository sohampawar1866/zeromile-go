// lib/ui/features/dev_panel/tabs/global_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/dev_panel_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';

class GlobalAnalyticsTab extends StatelessWidget {
  final DevPanelViewModel viewModel;

  const GlobalAnalyticsTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Cross-Domain Overview Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Global Cross-Domain Overview', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildRow('Total Active Rally Domains', '3 Configured'),
                _buildRow('Total Registered Citizen Accounts', '5,498 Verified Users'),
                _buildRow('Total Approved Contingent Groups', '52 Sub-Groups'),
                _buildRow('Total Seated SuperAdmins', '16 Across All Domains'),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Domain by Domain Breakdown
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Domain-by-Domain User Distribution', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildDomainStat('🚲 Cycling Rally 2026', '1,248 Users (LIVE NOW)', AppColors.success),
                _buildDomainStat('🏃 Nagpur City Marathon 2026', '3,400 Users (Scheduled)', AppColors.info),
                _buildDomainStat('📢 Citizen Protest Rally', '850 Users (Draft)', AppColors.warning),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Infrastructure Health & Load
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Infrastructure Health & Telemetry Latency', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildRow('Live WebSocket Connections', '2,140 Subscribed Channels'),
                _buildRow('Geolocation Ping Latency (P95)', '48 ms (Sub-50ms)'),
                _buildRow('Database Query Pool Utilization', '22% Operational Load'),
                _buildRow('OneSignal Background Channels', 'Active & Synchronized'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FluidTapScale(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Telemetry cache refreshed.'),
                              backgroundColor: AppColors.ink,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, size: 14, color: AppColors.ink),
                              SizedBox(width: AppSpacing.xs),
                              Text('Refresh', style: AppTypography.buttonSm),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FluidTapScale(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Database diagnostic snapshot exported.'),
                              backgroundColor: AppColors.ink,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download, size: 14, color: AppColors.ink),
                              SizedBox(width: AppSpacing.xs),
                              Text('Export DB', style: AppTypography.buttonSm),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.sm),
          Text(val, style: AppTypography.bodyStrong),
        ],
      ),
    );
  }

  Widget _buildDomainStat(String title, String subtitle, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.edgeInsetsCard,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: AppTypography.bodyStrong, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.xs),
          Text(subtitle, style: AppTypography.captionXs.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
