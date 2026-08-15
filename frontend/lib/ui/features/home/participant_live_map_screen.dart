// lib/ui/features/home/participant_live_map_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../models/route_checkpoint.dart';
import '../../../logic/view_models/participant_home_view_model.dart';
import '../../core/widgets/density_cluster_map_view.dart';
import '../../core/widgets/route_checkpoint_stepper.dart';
import '../../core/components/shad_card.dart';

class ParticipantLiveMapScreen extends StatelessWidget {
  final EventDomain? activeDomain;
  final List<RouteCheckpoint> checkpoints;
  final ParticipantHomeViewModel viewModel;
  final String currentUserId;

  const ParticipantLiveMapScreen({
    super.key,
    required this.activeDomain,
    required this.checkpoints,
    required this.viewModel,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = activeDomain?.status == EventDomainStatus.liveActive;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        onRefresh: () => viewModel.loadParticipantContext(
          domainId: activeDomain?.id ?? '',
          userId: currentUserId,
        ),
        child: ListView(
          padding: AppSpacing.edgeInsetsScreen,
          children: [
            // Map Visualizer
            ShadCard(
              title: isLive ? 'Live GPS Route Telemetry' : 'Official Route Geometry',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLive ? Icons.sensors : Icons.map_outlined,
                    color: isLive ? AppColors.success : AppColors.mute,
                    size: 15,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLive ? 'Online • 60 FPS' : 'Static Loop',
                    style: AppTypography.captionXs.copyWith(
                      color: isLive ? AppColors.success : AppColors.mute,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              child: DensityClusterMapView(
                title: '${activeDomain?.name ?? "Zero Mile"} Route Map',
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Route Checkpoints Stepper Card
            ShadCard(
              title: 'Official Route Checkpoints',
              trailing: Text(
                '${checkpoints.length} Stations',
                style: AppTypography.captionXs.copyWith(color: AppColors.mute),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RouteCheckpointStepper(
                    checkpoints: checkpoints,
                    completedIndex: isLive ? 1 : 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Safety & Aid Info Card
            ShadCard(
              title: 'Route Aid & Support Stations',
              child: Column(
                children: [
                  _buildAidRow(
                    icon: Icons.local_hospital_outlined,
                    color: AppColors.sale,
                    title: 'Medical Post: Law College Sq Aid Tent',
                    subtitle: 'Doctor and first responder ambulance on stand-by',
                  ),
                  const Divider(color: AppColors.hairlineSoft, height: 20),
                  _buildAidRow(
                    icon: Icons.water_drop_outlined,
                    color: AppColors.info,
                    title: 'Hydration Stations: Samvidhan & Shankar Nagar',
                    subtitle: 'Free water, electrolytes & energy fruits',
                  ),
                  const Divider(color: AppColors.hairlineSoft, height: 20),
                  _buildAidRow(
                    icon: Icons.build_outlined,
                    color: AppColors.charcoal,
                    title: 'Mobile Bike Repair Marshals',
                    subtitle: 'Patrolling every 15 min with tire pumps & repair kits',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAidRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyStrong),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }
}
