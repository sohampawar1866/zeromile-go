// lib/ui/features/leader_hub/tabs/leader_live_map_tab.dart

import 'package:flutter/material.dart';
import '../../../../logic/view_models/leader_hub_view_model.dart';
import '../../../../config/app_typography.dart';
import '../../../../config/app_spacing.dart';
import '../../../core/screens/live_map_fullscreen_screen.dart';

class LeaderLiveMapTab extends StatefulWidget {
  final LeaderHubViewModel viewModel;

  const LeaderLiveMapTab({super.key, required this.viewModel});

  @override
  State<LeaderLiveMapTab> createState() => _LeaderLiveMapTabState();
}

class _LeaderLiveMapTabState extends State<LeaderLiveMapTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final vm = widget.viewModel;

    return LiveMapFullscreenScreen(
      role: LiveMapRole.leader,
      liveLocations: vm.teamLocations,
      checkpoints: vm.routeCheckpoints,
      statsSheetContent: _buildStatsContent(vm),
    );
  }

  Widget _buildStatsContent(LeaderHubViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vm.groupName.isNotEmpty ? vm.groupName : 'Team',
          style: AppTypography.headingMd.copyWith(color: Colors.white),
        ),
        const SizedBox(height: AppSpacing.md),
        _statRow('Team Size', '${vm.totalEnrolled} Members'),
        _statRow('Check-in Rate',
            '${vm.checkinPercent.toStringAsFixed(1)}% Checked-in'),
        _statRow('Route Completion',
            '${vm.completionPercent.toStringAsFixed(1)}% Finished'),
        _statRow(
          'Live Location Streams',
          vm.teamLocations.isNotEmpty
              ? '${vm.teamLocations.length} Online'
              : 'Standby / Idle',
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTypography.bodySm
                  .copyWith(color: Colors.white60)),
          Text(value,
              style: AppTypography.bodyStrong
                  .copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
