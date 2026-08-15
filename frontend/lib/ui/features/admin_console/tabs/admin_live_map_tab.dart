// lib/ui/features/admin_console/tabs/admin_live_map_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_typography.dart';
import '../../../../config/app_spacing.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/screens/live_map_fullscreen_screen.dart';

class AdminLiveMapTab extends StatefulWidget {
  final SuperAdminViewModel viewModel;

  const AdminLiveMapTab({super.key, required this.viewModel});

  @override
  State<AdminLiveMapTab> createState() => _AdminLiveMapTabState();
}

class _AdminLiveMapTabState extends State<AdminLiveMapTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = widget.viewModel;

    return LiveMapFullscreenScreen(
      role: LiveMapRole.superAdmin,
      liveLocations: vm.allParticipantLocations,
      checkpoints: vm.routeCheckpoints,
      statsSheetContent: _buildStatsContent(vm),
    );
  }

  Widget _buildStatsContent(SuperAdminViewModel vm) {
    final densities = vm.sectorDensities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Telemetry strip
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Telemetry: 60 FPS  •  ${vm.activeRiderCount} Riders  •  ${vm.escalatedSosQueue.length} SOS Active',
                style: AppTypography.captionXs.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Group filter
        Text('Contingent Filter',
            style: AppTypography.bodyStrong.copyWith(color: Colors.white)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: vm.selectedGroupFilter,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('All Domain Participants',
                  overflow: TextOverflow.ellipsis),
            ),
            ...vm.subGroups.map((g) => DropdownMenuItem(
                  value: g.id,
                  child: Text('${g.name} (${g.orgType})',
                      overflow: TextOverflow.ellipsis),
                )),
          ],
          onChanged: (val) {
            if (val != null) vm.setSelectedGroupFilter(val);
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // Sector diagnostics
        Text('Sector Flow Diagnostics',
            style: AppTypography.bodyStrong.copyWith(color: Colors.white)),
        const SizedBox(height: AppSpacing.sm),
        if (densities.isNotEmpty)
          ...densities.map((sector) {
            final name = sector['name'] as String? ?? 'Sector';
            final count = sector['active_riders_nearby'] as int? ?? 0;
            final Color color;
            final String status;
            if (count > 250) {
              color = AppColors.clusterCoralRed;
              status = 'Dense ($count Riders)';
            } else if (count > 80) {
              color = AppColors.clusterAmber;
              status = 'Moderate ($count Riders)';
            } else {
              color = AppColors.clusterSkyBlue;
              status = 'Normal Flow ($count Riders)';
            }
            return _sectorRow(name, status, color);
          })
        else ...[
          _sectorRow('Sector 1: Samvidhan Square', 'Dense (320 Riders)',
              AppColors.clusterCoralRed),
          _sectorRow('Sector 2: Shankar Nagar Sq', 'Moderate (140 Riders)',
              AppColors.clusterAmber),
          _sectorRow('Sector 3: Law College Sq', 'Normal Flow (34 Riders)',
              AppColors.clusterSkyBlue),
          _sectorRow('Sector 4: Deekshabhoomi', 'Steady (85 Riders)',
              AppColors.clusterSkyBlue),
        ],

        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _sectorRow(String sector, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Text(sector,
                  style: AppTypography.bodySm.copyWith(color: Colors.white70),
                  overflow: TextOverflow.ellipsis)),
          const SizedBox(width: AppSpacing.xs),
          Row(
            children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: AppSpacing.xs),
              Text(status,
                  style: AppTypography.captionXs
                      .copyWith(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
