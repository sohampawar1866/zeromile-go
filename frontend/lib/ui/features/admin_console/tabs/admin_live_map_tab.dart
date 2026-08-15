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
    final activeRiders = viewModel.activeRiderCount;
    final activeGroups = viewModel.subGroups.length;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Hero Command Banner (Matching Participant Style)
        _buildHeroCommandBanner(activeRiders, activeGroups),

        const SizedBox(height: AppSpacing.md),

        // 2. City Telemetry Status Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.liveIndicatorBg,
            borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
            border: Border.all(color: AppColors.successBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Telemetry Stream: 60 FPS • $activeRiders Riders Live • ${viewModel.escalatedSosQueue.length} Critical SOS',
                  style: AppTypography.captionXs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.liveIndicatorText,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.sensors, color: AppColors.success, size: 16),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // 3. Live Density Visualizer
        ShadCard(
          title: 'Domain Real-time Density Visualizer',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.liveIndicatorBg,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Text(
              'LIVE RADAR',
              style: AppTypography.captionXs.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
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

        // 4. Group Filter
        ShadCard(
          title: 'Contingent Map Filter',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

        // 5. Sector Density & Flow Diagnostics
        ShadCard(
          title: 'Sector Flow & Diagnostics',
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

        const SizedBox(height: 88),
      ],
    );
  }

  Widget _buildHeroCommandBanner(int activeRiders, int activeGroups) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.admin_panel_settings_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMMAND CENTER',
                style: AppTypography.headingLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nagpur Municipal Operations • $activeRiders Active Telemetry Streams • $activeGroups Squads',
                style: AppTypography.caption.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
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
