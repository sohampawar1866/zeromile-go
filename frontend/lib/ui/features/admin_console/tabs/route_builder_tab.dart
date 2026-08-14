// lib/ui/features/admin_console/tabs/route_builder_tab.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/event_domain.dart';
import '../../../../models/route_checkpoint.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/widgets/fluid_tap_scale.dart';

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
      padding: AppSpacing.edgeInsetsScreen,
      children: [
        // Event Schedule & Timing Config
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Event Schedule & Timings',
                  style: AppTypography.headingMd,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Live GPS tracking, muster check-in, and floating SOS buttons are active strictly during these hours:',
                  style: AppTypography.bodySm,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: AppSpacing.edgeInsetsCard,
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                          border: Border.all(color: AppColors.hairlineSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: AppTypography.caption),
                            const SizedBox(height: AppSpacing.xxs),
                            Text('${_startDate.hour}:00 AM', style: AppTypography.bodyStrong),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Container(
                        padding: AppSpacing.edgeInsetsCard,
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                          border: Border.all(color: AppColors.hairlineSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: AppTypography.caption),
                            const SizedBox(height: AppSpacing.xxs),
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
                  decoration: const InputDecoration(labelText: 'Domain Lifecycle Status'),
                  dropdownColor: AppColors.canvas,
                  items: const [
                    DropdownMenuItem(
                      value: 'UPCOMING',
                      child: Text('UPCOMING (Pre-Event Mode)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'LIVE_ACTIVE',
                      child: Text('LIVE_ACTIVE (Rally Online)', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'CONCLUDED',
                      child: Text('CONCLUDED (Closed Mode)', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Route Geometry & Checkpoints
        Card(
          child: Padding(
            padding: AppSpacing.edgeInsetsCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Official Route & Checkpoints',
                  style: AppTypography.headingMd,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${widget.activeDomain?.name ?? "Event Route"} • ${widget.viewModel.routeCheckpoints.length} Checkpoints Configured',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.md),
                if (widget.viewModel.routeCheckpoints.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: const Text(
                      'No official checkpoints registered for this domain route yet.',
                      style: AppTypography.bodySm,
                    ),
                  )
                else
                  ...widget.viewModel.routeCheckpoints.map((cp) => _buildCheckpointPill(cp)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Save & Publish Route Action (Black Pill Button)
        FluidTapScale(
          onTap: () async {
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
                    content: Text('✓ Official route and event schedule published to all devices.'),
                    backgroundColor: AppColors.ink,
                  ),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
            ),
            alignment: Alignment.center,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 16, color: AppColors.onPrimary),
                SizedBox(width: AppSpacing.sm),
                Text('Publish Route & Schedule', style: AppTypography.buttonMd),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointPill(RouteCheckpoint cp) {
    Color tagColor;
    String tagLabel;
    switch (cp.checkpointType) {
      case CheckpointType.start:
        tagColor = AppColors.ink;
        tagLabel = '🚩 [Start]';
        break;
      case CheckpointType.finish:
        tagColor = AppColors.success;
        tagLabel = '🏁 [Finish]';
        break;
      case CheckpointType.waterStation:
        tagColor = AppColors.info;
        tagLabel = '💧 [Water]';
        break;
      case CheckpointType.medicalPost:
        tagColor = AppColors.sale;
        tagLabel = '🚑 [Medical]';
        break;
      case CheckpointType.diversion:
        tagColor = AppColors.warningAccent;
        tagLabel = '⚠️ [Diversion]';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        children: [
          Text(tagLabel, style: AppTypography.captionXs.copyWith(color: tagColor, fontWeight: FontWeight.bold)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(cp.name, style: AppTypography.bodySm, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
