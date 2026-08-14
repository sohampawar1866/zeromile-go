// lib/ui/features/dev_panel/dev_panel_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../logic/view_models/dev_panel_view_model.dart';
import 'tabs/provisioning_tab.dart';
import 'tabs/global_analytics_tab.dart';

class DevPanelScreen extends StatefulWidget {
  final EventDomain? activeDomain;
  final DevPanelViewModel viewModel;

  const DevPanelScreen({
    super.key,
    required this.activeDomain,
    required this.viewModel,
  });

  @override
  State<DevPanelScreen> createState() => _DevPanelScreenState();
}

class _DevPanelScreenState extends State<DevPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    widget.viewModel.loadGlobalMetrics();
    if (widget.activeDomain != null) {
      widget.viewModel.loadProvisionedAdmins(widget.activeDomain!.id);
    }
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
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.key, size: 16), SizedBox(width: 6), Text('Provisioning')])),
              Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.analytics_outlined, size: 16), SizedBox(width: 6), Text('Global Analytics')])),
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
              ProvisioningTab(
                viewModel: widget.viewModel,
                domainId: domainId,
              ),
              GlobalAnalyticsTab(
                viewModel: widget.viewModel,
              ),
            ],
          );
        },
      ),
    );
  }
}
