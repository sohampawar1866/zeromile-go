// lib/ui/features/admin_console/tabs/route_builder_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/event_domain.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';
import 'mapbox_route_studio_card.dart';

class RouteBuilderTab extends StatefulWidget {
  final EventDomain? activeDomain;
  final SuperAdminViewModel viewModel;

  const RouteBuilderTab({
    super.key,
    required this.activeDomain,
    required this.viewModel,
  });

  @override
  State<RouteBuilderTab> createState() => _RouteBuilderTabState();
}

class _RouteBuilderTabState extends State<RouteBuilderTab> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedStatus = 'LIVE_ACTIVE';

  @override
  void initState() {
    super.initState();
    _startDate = widget.activeDomain?.startTime ?? DateTime.now();
    _endDate = widget.activeDomain?.endTime ?? DateTime.now().add(const Duration(hours: 4));
    _selectedStatus = widget.activeDomain?.status.name.toUpperCase() ?? 'LIVE_ACTIVE';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      children: [
        // 1. Mapbox Standard 3D Route Studio
        MapboxRouteStudioCard(
          activeDomain: widget.activeDomain,
          existingCheckpoints: widget.viewModel.routeCheckpoints,
          viewModel: widget.viewModel,
          onRouteSaved: (waypoints, distanceKm) {
            if (widget.activeDomain != null) {
              widget.viewModel.updateRouteAndSchedule(
                domainId: widget.activeDomain!.id,
                startTime: _startDate,
                endTime: _endDate,
                status: _selectedStatus,
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.md),

        // 2. Event Schedule & Lifecycle Configuration Card
        ShadCard(
          title: 'Event Schedule & Timings',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.softCloud,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Text(
              _selectedStatus,
              style: AppTypography.captionXs.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Live GPS telemetry, attendance check-ins, and floating SOS emergency buttons are activated strictly during these hours:',
                style: AppTypography.bodySm,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Start Time', style: AppTypography.caption),
                          const SizedBox(height: 2),
                          Text('${_startDate.hour}:00 AM', style: AppTypography.bodyStrong),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('End Time', style: AppTypography.caption),
                          const SizedBox(height: 2),
                          Text('${_endDate.hour}:30 PM', style: AppTypography.bodyStrong),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedStatus.contains('ACTIVE') ? 'LIVE_ACTIVE' : 'UPCOMING',
                decoration: const InputDecoration(
                  labelText: 'Domain Lifecycle Status',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                dropdownColor: AppColors.canvas,
                items: const [
                  DropdownMenuItem(
                    value: 'UPCOMING',
                    child: Text('UPCOMING (Pre-Event Preview Mode)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'LIVE_ACTIVE',
                    child: Text('LIVE_ACTIVE (Rally Online Mode)', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: 'CONCLUDED',
                    child: Text('CONCLUDED (Closed Archive Mode)', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              ShadButton(
                text: 'Publish Route & Timings',
                icon: Icons.save_outlined,
                isFullWidth: true,
                variant: ShadButtonVariant.primary,
                onPressed: () async {
                  if (widget.activeDomain != null) {
                    final ok = await widget.viewModel.updateRouteAndSchedule(
                      domainId: widget.activeDomain!.id,
                      startTime: _startDate,
                      endTime: _endDate,
                      status: _selectedStatus,
                    );
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Route and schedule published to all citizen devices.'),
                          backgroundColor: AppColors.ink,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 88),
      ],
    );
  }
}
