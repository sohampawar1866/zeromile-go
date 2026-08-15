// lib/ui/features/home/participant_live_map_screen.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../models/event_domain.dart';
import '../../../models/route_checkpoint.dart';
import '../../../logic/view_models/participant_home_view_model.dart';
import '../../core/widgets/density_cluster_map_view.dart';
import '../../core/widgets/route_tracking_bottom_sheet.dart';
import '../../core/dialogs/emergency_sos_modal.dart';

class ParticipantLiveMapScreen extends StatefulWidget {
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
  State<ParticipantLiveMapScreen> createState() => _ParticipantLiveMapScreenState();
}

class _ParticipantLiveMapScreenState extends State<ParticipantLiveMapScreen> {
  final int _activeCheckpointIndex = 1;
  final double _distanceRemainingKm = 2.4;

  @override
  Widget build(BuildContext context) {
    final domain = widget.activeDomain ?? EventDomain(
      id: 'default-domain',
      name: 'ZeroMile Cycling Rally 2026',
      slug: 'cycling-2026',
      type: EventDomainType.cycling,
      status: EventDomainStatus.liveActive,
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      endTime: DateTime.now().add(const Duration(hours: 4)),
      createdAt: DateTime.now(),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // 1. Full-Screen Interactive Map Canvas (100% full screen)
          Positioned.fill(
            child: DensityClusterMapView(
              title: '${domain.name} Live Map',
              showHeader: false,
              showControls: false,
              checkpoints: widget.checkpoints,
              routeGeojson: domain.routeGeojson,
            ),
          ),

          // 2. SOS Button (Top-Right Corner, only 'SOS' text)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: AppSpacing.md,
            child: GestureDetector(
              onTap: () {
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
                          content: Text('Emergency SOS dispatched to Command Center & Marshals.'),
                          backgroundColor: AppColors.sale,
                        ),
                      );
                    }
                  },
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.sale,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sale.withOpacity(0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Streamlined Bottom Sheet (Milestone Stepper, Target & ETA)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RouteTrackingBottomSheet(
              checkpoints: widget.checkpoints,
              activeCheckpointIndex: _activeCheckpointIndex,
              distanceRemainingKm: _distanceRemainingKm,
              estimatedArrivalTime: '7:45 AM',
              nextCheckpointName: widget.checkpoints.isNotEmpty && widget.checkpoints.length > 1
                  ? widget.checkpoints[1].name
                  : 'Water Station 2',
            ),
          ),
        ],
      ),
    );
  }
}
