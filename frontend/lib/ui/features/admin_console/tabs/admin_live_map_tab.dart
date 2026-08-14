// lib/ui/features/admin_console/tabs/admin_live_map_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/density_cluster_map_view.dart';

class AdminLiveMapTab extends StatelessWidget {
  final SuperAdminViewModel viewModel;

  const AdminLiveMapTab({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Sub-Group Filter Dropdown Card
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FILTER PARTICIPANTS BY SUB-GROUP',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: viewModel.selectedGroupFilter,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  ),
                  dropdownColor: AppColors.canvas,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('All Domain Participants (1,248 Users)'),
                    ),
                    ...viewModel.subGroups.map((g) {
                      return DropdownMenuItem(
                        value: g.id,
                        child: Text('${g.name} (${g.orgType})'),
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
        ),
        const SizedBox(height: AppSpacing.md),

        // Live Domain Density Visualizer Card
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
                        'Domain Live Density Visualizer',
                        style: AppTypography.headingMd,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.sensors, size: 14, color: AppColors.success),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '60 FPS',
                          style: AppTypography.captionXs.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DensityClusterMapView(
                  title: viewModel.selectedGroupFilter.isEmpty
                      ? 'Nagpur Domain Loop (All General Crowd)'
                      : 'Nagpur Domain Loop (Filtered Contingent)',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Sector Density Stats
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sector Congestion & Flow Diagnostics', style: AppTypography.headingMd),
                const SizedBox(height: AppSpacing.md),
                _buildDiagnosticRow('Sector 1: Samvidhan Square', 'Dense (320 Riders)', AppColors.clusterCoralRed),
                _buildDiagnosticRow('Sector 2: Shankar Nagar Sq', 'Moderate (140 Riders)', AppColors.clusterAmber),
                _buildDiagnosticRow('Sector 3: Law College Sq', 'Normal Flow (34 Riders)', AppColors.clusterSkyBlue),
                _buildDiagnosticRow('Sector 4: Deekshabhoomi Finish', 'Steady Arrivals (85 Riders)', AppColors.clusterSkyBlue),
              ],
            ),
          ),
        ),
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
