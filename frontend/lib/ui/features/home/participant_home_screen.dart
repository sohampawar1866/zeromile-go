// lib/ui/features/home/participant_home_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/event_domain.dart';
import '../../../models/group_membership.dart';
import '../../../models/route_checkpoint.dart';
import '../../../utils/temporal_window_evaluator.dart';
import '../../../logic/view_models/participant_home_view_model.dart';
import '../../core/widgets/broadcast_card.dart';
import '../../core/dialogs/emergency_sos_modal.dart';
import '../../core/components/shad_card.dart';

class ParticipantHomeScreen extends StatefulWidget {
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
  State<ParticipantHomeScreen> createState() => _ParticipantHomeScreenState();
}

class _ParticipantHomeScreenState extends State<ParticipantHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final domain = widget.activeDomain ?? EventDomain(
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
        final membership = widget.viewModel.activeMembership;

        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: RefreshIndicator(
            color: AppColors.ink,
            backgroundColor: AppColors.surface,
            onRefresh: () => widget.viewModel.loadParticipantContext(
              domainId: domain.id,
              userId: widget.currentUserId,
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                // 1. Hero Upcoming / Live Event Banner (Reference Style)
                _buildHeroEventBanner(domain, isLive),

                const SizedBox(height: AppSpacing.md),

                // 2. Temporal Status Strip
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

                // 4. Featured Rally & Clubs Discovery Feed
                _buildEventDiscoveryCards(domain, isLive),

                const SizedBox(height: AppSpacing.md),

                // 5. Safety Broadcasts Card
                ShadCard(
                  title: 'Official Announcements',
                  trailing: Text(
                    '${widget.viewModel.broadcasts.length} Messages',
                    style: AppTypography.captionXs.copyWith(color: AppColors.mute),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.viewModel.broadcasts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Text(
                            'No broadcasts posted yet for this domain.',
                            style: AppTypography.caption,
                          ),
                        )
                      else
                        ...widget.viewModel.broadcasts.take(3).map((b) => BroadcastCard(message: b)),
                    ],
                  ),
                ),

                const SizedBox(height: 88),
              ],
            ),
          ),
          floatingActionButton: isLive
              ? Container(
                  height: 44,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x44EF4444),
                        offset: Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      EmergencySosModal.show(
                        context,
                        onTrigger: (type) async {
                          final ok = await widget.viewModel.triggerEmergencySos(
                            domainId: domain.id,
                            userId: widget.currentUserId,
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
                    icon: const Icon(Icons.shield, color: AppColors.onPrimary, size: 18),
                    label: const Text(
                      'EMERGENCY SOS',
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

  Widget _buildHeroEventBanner(EventDomain domain, bool isLive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle bike icon
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(
              Icons.directions_bike_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.12),
            ),
          ),

          // Minimalist Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                domain.name,
                style: AppTypography.headingLg.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Action Button
              ElevatedButton.icon(
                onPressed: widget.onNavigateToMap,
                icon: const Icon(Icons.map_outlined, size: 15, color: Color(0xFF1D4ED8)),
                label: Text(
                  isLive ? 'Track Live Route' : 'Preview Route',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D4ED8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventDiscoveryCards(EventDomain domain, bool isLive) {
    final scheduleText = _formatEventSchedule(domain.startTime, domain.endTime);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  domain.name,
                  style: AppTypography.headingMd,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.success.withOpacity(0.1) : AppColors.softCloud,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: isLive ? AppColors.successBorder : AppColors.hairline,
                  ),
                ),
                child: Text(
                  isLive ? 'LIVE NOW' : 'UPCOMING',
                  style: AppTypography.captionXs.copyWith(
                    color: isLive ? AppColors.success : AppColors.mute,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            'Nagpur Central Circuit • Start: Samvidhan Square',
            style: AppTypography.caption.copyWith(color: AppColors.mute),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Direct Schedule Timestamp Row
          Row(
            children: [
              const Icon(Icons.schedule, size: 14, color: AppColors.ink),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  scheduleText,
                  style: AppTypography.captionXs.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onNavigateToMap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              child: Text(
                isLive ? 'Open Live Route Map' : 'Explore Circuit Waypoints',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventSchedule(DateTime start, DateTime end) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[start.month.clamp(1, 12) - 1];
    final startHour = start.hour > 12 ? start.hour - 12 : (start.hour == 0 ? 12 : start.hour);
    final startAmPm = start.hour >= 12 ? 'PM' : 'AM';
    final startMin = start.minute.toString().padLeft(2, '0');

    final endHour = end.hour > 12 ? end.hour - 12 : (end.hour == 0 ? 12 : end.hour);
    final endAmPm = end.hour >= 12 ? 'PM' : 'AM';
    final endMin = end.minute.toString().padLeft(2, '0');

    return '${start.day} $month ${start.year} • $startHour:$startMin $startAmPm - $endHour:$endMin $endAmPm';
  }
}
