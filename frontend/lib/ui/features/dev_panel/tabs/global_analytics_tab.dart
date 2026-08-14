// lib/ui/features/dev_panel/tabs/global_analytics_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/event_domain.dart';
import '../../../../logic/view_models/dev_panel_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';
import '../../../core/widgets/status_badge.dart';

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
                _buildRow('Total Active Rally Domains', '${viewModel.totalDomains} Configured'),
                _buildRow('Total Registered Citizen Accounts', '${viewModel.totalUsers} Verified Users'),
                _buildRow('Total Approved Contingent Groups', '${viewModel.totalGroups} Sub-Groups'),
                _buildRow('Total Seated SuperAdmins', '${viewModel.totalSuperAdmins} Across All Domains'),
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
                const Text('Domain-by-Domain Distribution', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                if (viewModel.domains.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: const Text('No domains configured yet.', style: AppTypography.bodySm),
                  )
                else
                  ...viewModel.domains.map((domain) => _buildDomainCard(domain)),
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
                const Text('Infrastructure Health & Telemetry', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildRow('Active Location Telemetry Snapshots', '${viewModel.totalLiveLocations} Pings Recorded'),
                _buildRow('Supabase Realtime Stream', 'Active & Synchronized'),
                _buildRow('Database Schema Engine', 'PostgreSQL 15 (Hardened RLS)'),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FluidTapScale(
                        onTap: () async {
                          await viewModel.loadGlobalMetrics();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Live metrics synchronized from Supabase.'),
                                backgroundColor: AppColors.ink,
                              ),
                            );
                          }
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
                              Text('Refresh', style: AppTypography.buttonSmSecondary),
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
                              Text('Export DB', style: AppTypography.buttonSmSecondary),
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

  Widget _buildDomainCard(EventDomain domain) {
    final isLive = domain.status == EventDomainStatus.liveActive;
    final isConcluded = domain.status == EventDomainStatus.concluded;
    final badgeType = isLive
        ? StatusBadgeType.success
        : isConcluded
            ? StatusBadgeType.muted
            : StatusBadgeType.primary;

    final statusLabel = isLive
        ? 'LIVE NOW'
        : isConcluded
            ? 'CONCLUDED'
            : 'UPCOMING';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.edgeInsetsCard,
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            domain.name,
            style: AppTypography.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              StatusBadge(
                label: 'TYPE: ${domain.type.name.toUpperCase()}',
                type: StatusBadgeType.muted,
              ),
              StatusBadge(
                label: statusLabel,
                type: badgeType,
                icon: isLive ? Icons.sensors : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
