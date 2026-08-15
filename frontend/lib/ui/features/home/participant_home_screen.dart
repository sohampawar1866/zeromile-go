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
import '../../core/components/shad_card.dart';
import 'components/presence_tracker_card.dart';
import 'components/live_route_card.dart';
import 'components/active_group_card.dart';

class ParticipantHomeScreen extends StatelessWidget {
  final EventDomain? activeDomain;
  final List<RouteCheckpoint> checkpoints;
  final ParticipantHomeViewModel viewModel;
  final String currentUserId;
  final VoidCallback onNavigateToGroups;
  final VoidCallback? onNavigateToMap;

  const ParticipantHomeScreen({
    super.key,
    required this.activeDomain,
    required this.checkpoints,
    required this.viewModel,
    required this.currentUserId,
    required this.onNavigateToGroups,
    this.onNavigateToMap,
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
            backgroundColor: AppColors.surface,
            onRefresh: () => viewModel.loadParticipantContext(
              domainId: domain.id,
              userId: currentUserId,
            ),
            child: ListView(
              padding: AppSpacing.edgeInsetsScreen,
              children: [
                // Temporal Schedule Live Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLive ? AppColors.liveIndicatorBg : AppColors.surface,
                    borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                    border: Border.all(
                      color: isLive ? AppColors.successBorder : AppColors.hairline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.success : AppColors.mute,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          bannerText,
                          style: AppTypography.captionXs.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isLive ? AppColors.liveIndicatorText : AppColors.ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        isLive ? Icons.sensors : Icons.schedule,
                        color: isLive ? AppColors.success : AppColors.mute,
                        size: 16,
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
                ShadCard(
                  title: 'Safety Broadcasts',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (viewModel.broadcasts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Text(
                            'No broadcasts posted yet for this domain.',
                            style: AppTypography.caption,
                          ),
                        )
                      else
                        ...viewModel.broadcasts.take(3).map((b) => BroadcastCard(message: b)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Active Group Card
                ActiveGroupCard(
                  membership: viewModel.activeMembership,
                  onManageGroups: onNavigateToGroups,
                ),
                const SizedBox(height: 88),
              ],
            ),
          ),
          floatingActionButton: isLive
              ? Container(
                  height: 42,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33EF4444),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
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
                                content: Text('Emergency SOS dispatched to Command Center.'),
                                backgroundColor: AppColors.sale,
                              ),
                            );
                          }
                        },
                      );
                    },
                    backgroundColor: AppColors.sale,
                    foregroundColor: AppColors.onPrimary,
                    elevation: 0,
                    highlightElevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                    ),
                    icon: const Icon(Icons.shield, color: AppColors.onPrimary, size: 16),
                    label: const Text(
                      'SOS DISTRESS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
