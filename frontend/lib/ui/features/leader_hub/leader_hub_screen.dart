// lib/ui/features/leader_hub/leader_hub_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../data/models/event_domain.dart';
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
      appBar: AppBar(
        title: const Text('Group Leader Hub'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.ink,
          indicatorWeight: 2.5,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.mute,
          labelStyle: AppTypography.buttonSm,
          tabs: const [
            Tab(icon: Icon(Icons.groups_outlined), text: 'Team Hub'),
            Tab(icon: Icon(Icons.location_on_outlined), text: 'Live Map'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
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
      ),
    );
  }
}
