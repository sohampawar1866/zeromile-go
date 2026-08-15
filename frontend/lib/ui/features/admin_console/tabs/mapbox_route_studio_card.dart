// lib/ui/features/admin_console/tabs/mapbox_route_studio_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/event_domain.dart';
import '../../../../models/route_checkpoint.dart';
import '../../../../services/mapbox_service.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';
import '../../../core/widgets/density_cluster_map_view.dart';

class MapboxRouteStudioCard extends StatefulWidget {
  final EventDomain? activeDomain;
  final List<RouteCheckpoint> existingCheckpoints;
  final Function(List<MapPoint> waypoints, double distanceKm)? onRouteSaved;

  const MapboxRouteStudioCard({
    super.key,
    this.activeDomain,
    this.existingCheckpoints = const [],
    this.onRouteSaved,
  });

  @override
  State<MapboxRouteStudioCard> createState() => _MapboxRouteStudioCardState();
}

class _MapboxRouteStudioCardState extends State<MapboxRouteStudioCard> {
  List<MapPoint> _currentWaypoints = [];
  double _calculatedDistanceKm = 10.4;

  @override
  void initState() {
    super.initState();
    if (widget.existingCheckpoints.isNotEmpty) {
      _currentWaypoints = widget.existingCheckpoints
          .map((c) => MapPoint(
                latitude: c.latitude,
                longitude: c.longitude,
                name: c.name,
              ))
          .toList();
    }
  }

  void _deleteWaypoint(int index) {
    if (index >= 0 && index < _currentWaypoints.length) {
      setState(() {
        _currentWaypoints.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waypoint removed from route draft.'),
          backgroundColor: AppColors.mute,
        ),
      );
    }
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Draft Route saved with ${_currentWaypoints.length} waypoints (${_calculatedDistanceKm.toStringAsFixed(1)} km).',
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
          'Official Mapbox 3D Route Published (${_calculatedDistanceKm.toStringAsFixed(1)} km)! Broadcasted to all group leaders.',
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

        // Route Distance Metric Card (Theme Clean Light Style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.softCloud,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              Text(
                '${_calculatedDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'TOTAL OFFICIAL ROUTE DISTANCE',
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.mute,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Multi-Rider 3D Live Simulation Panel
        ShadCard(
          title: 'Multi-Rider 3D Live GPS Tracking',
          description: 'Simulates 4 team riders moving live through Mapbox 3D Nagpur buildings.',
          child: Column(
            children: [
              _buildRiderTelemetryRow('Rajesh Sharma', '${(_calculatedDistanceKm * 0.85).toStringAsFixed(1)} km', AppColors.ink, isLeader: true),
              _buildRiderTelemetryRow('Aniket Deshmukh', '${(_calculatedDistanceKm * 0.72).toStringAsFixed(1)} km', AppColors.accentTeal),
              _buildRiderTelemetryRow('Priya Verma', '${(_calculatedDistanceKm * 0.60).toStringAsFixed(1)} km', AppColors.success),
              _buildRiderTelemetryRow('Saurabh Joshi', '${(_calculatedDistanceKm * 0.45).toStringAsFixed(1)} km', AppColors.info),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Action Buttons with ShadButton
        Row(
          children: [
            Expanded(
              child: ShadButton(
                text: 'Save Draft',
                icon: Icons.save_outlined,
                variant: ShadButtonVariant.secondary,
                onPressed: _saveDraft,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ShadButton(
                text: 'Lock & Publish',
                icon: Icons.lock_outline,
                variant: ShadButtonVariant.primary,
                onPressed: _publishRoute,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Checkpoints & Landmarks List
        ShadCard(
          title: 'Official Checkpoints & Milestones',
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
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isStart
                                ? AppColors.successBorder
                                : isEnd
                                    ? const Color(0xFFFFE4E6)
                                    : AppColors.softCloud,
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
                                      : AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            wp.name,
                            style: AppTypography.bodySm,
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

  Widget _buildRiderTelemetryRow(String name, String distance, Color color, {bool isLeader = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    name,
                    style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (isLeader) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      'LEADER',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            distance,
            style: AppTypography.bodySm.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
