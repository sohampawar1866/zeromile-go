// lib/ui/features/leader_hub/leader_hub_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../logic/view_models/leader_hub_view_model.dart';
import 'tabs/team_hub_tab.dart';
import 'tabs/leader_live_map_tab.dart';
import 'tabs/leader_analytics_tab.dart';

class LeaderHubScreen extends StatefulWidget {
  final EventDomain? activeDomain;
  final LeaderHubViewModel viewModel;
  final String leaderUserId;
  final String groupId;

  const LeaderHubScreen({
    super.key,
    required this.activeDomain,
    required this.viewModel,
    required this.leaderUserId,
    required this.groupId,
  });

  @override
  State<LeaderHubScreen> createState() => _LeaderHubScreenState();
}

class _LeaderHubScreenState extends State<LeaderHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final domainId = widget.activeDomain?.id ?? 'cycling-domain';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(42),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            border: Border(bottom: BorderSide(color: AppColors.hairlineSoft, width: 1.0)),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.ink,
            indicatorWeight: 2.0,
            labelColor: AppColors.ink,
            unselectedLabelColor: AppColors.mute,
            labelStyle: AppTypography.buttonSm,
            tabs: const [
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.groups_outlined, size: 16), SizedBox(width: 6), Text('Team Hub')])),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.location_on_outlined, size: 16), SizedBox(width: 6), Text('Live Map')])),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.bar_chart, size: 16), SizedBox(width: 6), Text('Analytics')])),
            ],
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              TeamHubTab(
                viewModel: widget.viewModel,
                domainId: domainId,
                groupId: widget.groupId,
                leaderUserId: widget.leaderUserId,
              ),
              LeaderLiveMapTab(
                viewModel: widget.viewModel,
              ),
              LeaderAnalyticsTab(
                viewModel: widget.viewModel,
              ),
            ],
          );
        },
      ),
    );
  }
}
