// lib/ui/features/home/participant_home_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../models/route_checkpoint.dart';
import '../../../utils/temporal_window_evaluator.dart';
import '../../../logic/view_models/participant_home_view_model.dart';
import '../../core/widgets/broadcast_card.dart';
import '../../core/dialogs/emergency_sos_modal.dart';
import 'components/presence_tracker_card.dart';
import 'components/live_route_card.dart';
import 'components/active_group_card.dart';

class ParticipantHomeScreen extends StatelessWidget {
  final EventDomain? activeDomain;
  final List<RouteCheckpoint> checkpoints;
  final ParticipantHomeViewModel viewModel;
  final String currentUserId;
  final VoidCallback onNavigateToGroups;
  final VoidCallback onOpenProposeModal;

  const ParticipantHomeScreen({
    super.key,
    required this.activeDomain,
    required this.checkpoints,
    required this.viewModel,
    required this.currentUserId,
    required this.onNavigateToGroups,
    required this.onOpenProposeModal,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final domain = activeDomain ?? EventDomain(
          id: 'default-domain',
          name: 'Cycling Rally 2026',
          slug: 'cycling-2026',
          type: EventDomainType.cycling,
          status: EventDomainStatus.liveActive,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 4)),
          createdAt: DateTime.now(),
        );

        final isLive = domain.status == EventDomainStatus.liveActive;
        final bannerText = TemporalWindowEvaluator.getScheduleBanner(domain);

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: RefreshIndicator(
            color: AppColors.ink,
            backgroundColor: AppColors.canvas,
            onRefresh: () => viewModel.loadParticipantContext(
              domainId: domain.id,
              userId: currentUserId,
            ),
        child: ListView(
          padding: AppSpacing.edgeInsetsScreen,
          children: [
            // Temporal Schedule Banner (Nike Soft Cloud Banner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: isLive ? AppColors.successBg : AppColors.softCloud,
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
                border: Border.all(
                  color: isLive ? AppColors.successBorder : AppColors.hairlineSoft,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isLive ? Icons.sensors : Icons.event_available,
                    color: isLive ? AppColors.success : AppColors.ink,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      bannerText,
                      style: AppTypography.captionXs.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isLive ? AppColors.success : AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Presence / Check-In Card
            PresenceTrackerCard(
              membership: viewModel.activeMembership,
              isLiveWindow: isLive,
              onCheckIn: () async {
                final ok = await viewModel.checkInAtMuster(
                  domainId: domain.id,
                  userId: currentUserId,
                );
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checked In! Muster roll attendance recorded.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              onComplete: () async {
                final ok = await viewModel.completeRally(
                  domainId: domain.id,
                  userId: currentUserId,
                );
                if (context.mounted && ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rally finish recorded! Pass registered.'),
                      backgroundColor: AppColors.ink,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // Live Interactive Route Card
            LiveRouteCard(
              checkpoints: checkpoints,
              isLiveWindow: isLive,
            ),
            const SizedBox(height: AppSpacing.md),

            // Broadcasts Feed Card
            Card(
              child: Padding(
                padding: AppSpacing.edgeInsetsCard,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign, color: AppColors.warning, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Latest Safety Broadcasts', style: AppTypography.headingMd),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (viewModel.broadcasts.isEmpty)
                      const Text(
                        'No broadcasts posted yet for this domain.',
                        style: AppTypography.caption,
                      )
                    else
                      ...viewModel.broadcasts.take(3).map((b) => BroadcastCard(message: b)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Active Group Card
            ActiveGroupCard(
              membership: viewModel.activeMembership,
              onSwitchGroup: onNavigateToGroups,
              onProposeGroup: onOpenProposeModal,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: isLive
          ? FloatingActionButton.extended(
              onPressed: () {
                EmergencySosModal.show(
                  context,
                  onTrigger: (type) async {
                    final ok = await viewModel.triggerEmergencySos(
                      domainId: domain.id,
                      userId: currentUserId,
                      emergencyType: type,
                    );
                    if (context.mounted && ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🚨 Emergency SOS dispatched to Command Center.'),
                          backgroundColor: AppColors.sale,
                        ),
                      );
                    }
                  },
                );
              },
              backgroundColor: AppColors.sale,
              foregroundColor: AppColors.onPrimary,
              elevation: 3,
              icon: const Icon(Icons.emergency_share, color: AppColors.onPrimary, size: 20),
              label: const Text(
                'EMERGENCY SOS',
                style: AppTypography.buttonLg,
              ),
            )
          : null,
        );
      },
    );
  }
}
