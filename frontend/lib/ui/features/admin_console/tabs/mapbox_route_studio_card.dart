// lib/ui/features/admin_console/tabs/mapbox_route_studio_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/event_domain.dart';
import '../../../../models/route_checkpoint.dart';
import '../../../../services/mapbox_service.dart';
import '../../../core/widgets/density_cluster_map_view.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';

class MapboxRouteStudioCard extends StatefulWidget {
  final EventDomain? activeDomain;
  final List<RouteCheckpoint> existingCheckpoints;
  final Function(List<MapPoint> waypoints, double distanceKm)? onRouteSaved;

  const MapboxRouteStudioCard({
    super.key,
    required this.activeDomain,
    required this.existingCheckpoints,
    this.onRouteSaved,
  });

  @override
  State<MapboxRouteStudioCard> createState() => _MapboxRouteStudioCardState();
}

class _MapboxRouteStudioCardState extends State<MapboxRouteStudioCard> {
  List<MapPoint> _currentWaypoints = [];
  double _calculatedDistanceKm = 0.0;

  @override
  void initState() {
    super.initState();
    _currentWaypoints = widget.existingCheckpoints
        .map((cp) => MapPoint(
              latitude: cp.latitude,
              longitude: cp.longitude,
              name: cp.name,
              tag: cp.checkpointType.name.toUpperCase(),
            ))
        .toList();
  }

  void _deleteWaypoint(int index) {
    if (index >= 0 && index < _currentWaypoints.length) {
      setState(() {
        _currentWaypoints.removeAt(index);
      });
    }
  }

  void _saveDraft() {
    if (_currentWaypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure at least Start and End points before saving.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    widget.onRouteSaved?.call(_currentWaypoints, _calculatedDistanceKm);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '💾 Route Draft Saved: ${_calculatedDistanceKm.toStringAsFixed(1)} km with ${_currentWaypoints.length} checkpoints.',
        ),
        backgroundColor: AppColors.ink,
      ),
    );
  }

  void _publishRoute() {
    if (_currentWaypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select Start and End points to publish the official route.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    widget.onRouteSaved?.call(_currentWaypoints, _calculatedDistanceKm);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🔒 Official Mapbox 3D Route Published (${_calculatedDistanceKm.toStringAsFixed(1)} km)! Broadcasted to all contingent leaders.',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mapbox 3D Interactive Map Canvas
        DensityClusterMapView(
          title: 'Mapbox Standard 3D Route Studio (Nagpur)',
          isInteractiveRouteBuilder: true,
          checkpoints: widget.existingCheckpoints,
          onWaypointsChanged: (pts) => setState(() => _currentWaypoints = pts),
          onDistanceCalculated: (dist) => setState(() => _calculatedDistanceKm = dist),
        ),
        const SizedBox(height: AppSpacing.md),

        // Glowing Radium Route Distance Telemetry Tile (JetBrains Mono style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF131B2E),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0x6600FF66)),
            boxShadow: const [
              BoxShadow(color: Color(0x2200FF66), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${_calculatedDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Courier',
                  color: Color(0xFF00FF66),
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(color: Color(0xAA00FF66), blurRadius: 12),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'TOTAL OFFICIAL MAPBOX 3D CYCLING DISTANCE',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Multi-Rider 3D Live Simulation Panel
        ShadCard(
          title: '🚴 Multi-Rider 3D Live GPS Tracking',
          description: 'Simulates 4 team riders moving live through Mapbox 3D Nagpur buildings.',
          child: Column(
            children: [
              _buildRiderTelemetryRow('👑 Rajesh Sharma (Leader)', '${(_calculatedDistanceKm * 0.85).toStringAsFixed(1)} km', const Color(0xFFFF9100)),
              _buildRiderTelemetryRow('🚴 Aniket Deshmukh', '${(_calculatedDistanceKm * 0.72).toStringAsFixed(1)} km', const Color(0xFF00F2FE)),
              _buildRiderTelemetryRow('🚴 Priya Verma', '${(_calculatedDistanceKm * 0.60).toStringAsFixed(1)} km', const Color(0xFF00FF66)),
              _buildRiderTelemetryRow('🚴 Saurabh Joshi', '${(_calculatedDistanceKm * 0.45).toStringAsFixed(1)} km', const Color(0xFF2979FF)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Action Buttons with ShadButton
        Row(
          children: [
            Expanded(
              child: ShadButton(
                text: '💾 Save Draft',
                variant: ShadButtonVariant.secondary,
                onPressed: _saveDraft,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ShadButton(
                text: '🔒 Lock & Publish',
                variant: ShadButtonVariant.primary,
                onPressed: _publishRoute,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Checkpoints & Landmarks List
        ShadCard(
          title: '🏁 Official Checkpoints & Milestones',
          trailing: Text('${_currentWaypoints.length} Points', style: AppTypography.caption),
          child: Column(
            children: [
              if (_currentWaypoints.isEmpty)
                const Text('No checkpoints configured. Use map search to add points.', style: AppTypography.caption)
              else
                ..._currentWaypoints.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final wp = entry.value;
                  final isStart = idx == 0;
                  final isEnd = idx == _currentWaypoints.length - 1 && _currentWaypoints.length > 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0F19),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: const Color(0xFF27272A)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isStart
                                ? const Color(0x2200FF66)
                                : isEnd
                                    ? const Color(0x22FF1744)
                                    : const Color(0x2200F2FE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isStart ? 'START' : isEnd ? 'FINISH' : 'WAYPOINT ${idx + 1}',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: isStart
                                  ? AppColors.success
                                  : isEnd
                                      ? AppColors.sale
                                      : AppColors.info,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            wp.name,
                            style: AppTypography.bodySm.copyWith(color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.mute),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _deleteWaypoint(idx),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRiderTelemetryRow(String name, String distance, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color, blurRadius: 4)])),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          Text(distance, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Courier', color: Color(0xFF00FF66))),
        ],
      ),
    );
  }
}
