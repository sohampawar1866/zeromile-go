// lib/ui/features/admin_console/superadmin_console_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../logic/view_models/superadmin_view_model.dart';
import 'tabs/governance_tab.dart';
import 'tabs/admin_live_map_tab.dart';
import 'tabs/route_builder_tab.dart';
import 'tabs/admin_analytics_tab.dart';

class SuperAdminConsoleScreen extends StatefulWidget {
  final EventDomain? activeDomain;
  final SuperAdminViewModel viewModel;
  final String adminUserId;

  const SuperAdminConsoleScreen({
    super.key,
    required this.activeDomain,
    required this.viewModel,
    required this.adminUserId,
  });

  @override
  State<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final domainId = widget.activeDomain?.id ?? 'cycling-domain';
    widget.viewModel.loadAdminContext(domainId);
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
        title: const Text('SuperAdmin Command Center'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.ink,
          indicatorWeight: 2.5,
          labelColor: AppColors.ink,
          unselectedLabelColor: AppColors.mute,
          labelStyle: AppTypography.buttonSm,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.shield_outlined), text: 'Governance'),
            Tab(icon: Icon(Icons.location_on_outlined), text: 'Live Map'),
            Tab(icon: Icon(Icons.alt_route), text: 'Route & Schedule'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Analytics'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              GovernanceTab(
                viewModel: widget.viewModel,
                domainId: domainId,
                adminUserId: widget.adminUserId,
              ),
              AdminLiveMapTab(
                viewModel: widget.viewModel,
              ),
              RouteBuilderTab(
                activeDomain: widget.activeDomain,
                viewModel: widget.viewModel,
              ),
              AdminAnalyticsTab(
                viewModel: widget.viewModel,
              ),
            ],
          );
        },
      ),
    );
  }
}
