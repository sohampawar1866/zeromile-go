// lib/ui/features/home/participant_live_map_screen.dart

import 'package:flutter/material.dart';
import '../../../models/event_domain.dart';
import '../../../models/route_checkpoint.dart';
import '../../../logic/view_models/participant_home_view_model.dart';
import '../../core/screens/live_map_fullscreen_screen.dart';

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
  State<ParticipantLiveMapScreen> createState() =>
      _ParticipantLiveMapScreenState();
}

class _ParticipantLiveMapScreenState extends State<ParticipantLiveMapScreen> {
  final int _activeCheckpointIndex = 1;
  final double _distanceRemainingKm = 2.4;

  @override
  Widget build(BuildContext context) {
    final domain = widget.activeDomain ??
        EventDomain(
          id: 'default-domain',
          name: 'ZeroMile Cycling Rally 2026',
          slug: 'cycling-2026',
          type: EventDomainType.cycling,
          status: EventDomainStatus.liveActive,
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 4)),
          createdAt: DateTime.now(),
        );

    // Group member live locations — show if any exist, else just own position
    final groupMemberLocations = widget.viewModel.groupMemberLocations;

    return LiveMapFullscreenScreen(
      role: LiveMapRole.participant,
      liveLocations: groupMemberLocations,
      checkpoints: widget.checkpoints,
      currentUserId: widget.currentUserId,
      domainId: domain.id,
      onSosTrigger: (userId, domainId, emergencyType) =>
          widget.viewModel.triggerEmergencySos(
        domainId: domainId,
        userId: userId,
        type: emergencyType.name, // converts enum to string e.g. 'medical'
      ),
      activeCheckpointIndex: _activeCheckpointIndex,
      distanceRemainingKm: _distanceRemainingKm,
      estimatedArrivalTime: '7:45 AM',
    );
  }
}
