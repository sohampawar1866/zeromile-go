// lib/ui/features/admin_console/tabs/admin_live_map_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/density_cluster_map_view.dart';
import '../../../core/components/shad_card.dart';

class AdminLiveMapTab extends StatefulWidget {
  final SuperAdminViewModel viewModel;

  const AdminLiveMapTab({super.key, required this.viewModel});

  @override
  State<AdminLiveMapTab> createState() => _AdminLiveMapTabState();
}

class _AdminLiveMapTabState extends State<AdminLiveMapTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewModel = widget.viewModel;
    final densities = viewModel.sectorDensities;

    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Live Domain Density Visualizer Card
        ShadCard(
          title: 'Domain Live Density Visualizer',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sensors, size: 14, color: AppColors.success),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '60 FPS Telemetry',
                style: AppTypography.captionXs.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DensityClusterMapView(
                title: viewModel.selectedGroupFilter.isEmpty
                    ? 'Nagpur Route Loop (All Riders)'
                    : 'Nagpur Route Loop (Filtered Group)',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Sub-Group Filter Dropdown Card
        ShadCard(
          title: 'Filter Map by Group',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter live GPS map by specific club or view all riders:',
                style: AppTypography.caption,
              ),

              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: viewModel.selectedGroupFilter,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                ),
                dropdownColor: AppColors.canvas,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text(
                      'All Domain Participants (Domain-wide)',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ...viewModel.subGroups.map((g) {
                    return DropdownMenuItem(
                      value: g.id,
                      child: Text(
                        '${g.name} (${g.orgType})',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                onChanged: (val) {
                  if (val != null) viewModel.setSelectedGroupFilter(val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Sector Density Stats Card
        ShadCard(
          title: 'Sector Congestion & Flow Diagnostics',
          trailing: Text(
            '${densities.isNotEmpty ? densities.length : 4} Sectors',
            style: AppTypography.captionXs.copyWith(color: AppColors.mute),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (densities.isNotEmpty)
                ...densities.map((sector) {
                  final name = sector['name'] as String? ?? 'Checkpoint';
                  final count = sector['active_riders_nearby'] as int? ?? 0;
                  final Color statusColor;
                  final String statusText;

                  if (count > 250) {
                    statusColor = AppColors.clusterCoralRed;
                    statusText = 'Dense ($count Riders)';
                  } else if (count > 80) {
                    statusColor = AppColors.clusterAmber;
                    statusText = 'Moderate ($count Riders)';
                  } else {
                    statusColor = AppColors.clusterSkyBlue;
                    statusText = 'Normal Flow ($count Riders)';
                  }

                  return _buildDiagnosticRow(name, statusText, statusColor);
                })
              else ...[
                _buildDiagnosticRow('Sector 1: Samvidhan Square', 'Dense (320 Riders)', AppColors.clusterCoralRed),
                _buildDiagnosticRow('Sector 2: Shankar Nagar Sq', 'Moderate (140 Riders)', AppColors.clusterAmber),
                _buildDiagnosticRow('Sector 3: Law College Sq', 'Normal Flow (34 Riders)', AppColors.clusterSkyBlue),
                _buildDiagnosticRow('Sector 4: Deekshabhoomi Finish', 'Steady Arrivals (85 Riders)', AppColors.clusterSkyBlue),
              ],
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildDiagnosticRow(String sector, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(sector, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.xs),
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.xs),
              Text(status, style: AppTypography.captionXs.copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
