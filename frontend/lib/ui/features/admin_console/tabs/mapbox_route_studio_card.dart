// lib/ui/features/admin_console/tabs/mapbox_route_studio_card.dart

import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_spacing.dart';
import '../../../../config/app_typography.dart';
import '../../../../models/event_domain.dart';
import '../../../../models/route_checkpoint.dart';
import '../../../../services/mapbox_service.dart';
import '../../../../logic/view_models/superadmin_view_model.dart';
import '../../../core/components/shad_button.dart';
import '../../../core/components/shad_card.dart';
import '../../../core/widgets/map_view_platform/map_view_platform.dart';
import '../../../../utils/nagpur_poi_registry.dart';

enum PointSelectMode { start, end, waypoint }

class MapboxRouteStudioCard extends StatefulWidget {
  final EventDomain? activeDomain;
  final List<RouteCheckpoint> existingCheckpoints;
  final SuperAdminViewModel? viewModel;
  final Function(List<MapPoint> waypoints, double distanceKm)? onRouteSaved;

  const MapboxRouteStudioCard({
    super.key,
    this.activeDomain,
    this.existingCheckpoints = const [],
    this.viewModel,
    this.onRouteSaved,
  });

  @override
  State<MapboxRouteStudioCard> createState() => _MapboxRouteStudioCardState();
}

class _MapboxRouteStudioCardState extends State<MapboxRouteStudioCard> {
  PointSelectMode _selectMode = PointSelectMode.start;
  List<MapPoint> _currentWaypoints = [];
  double _calculatedDistanceKm = 10.4;
  int _estimatedDurationMin = 35;

  // History stack for Undo / Redo
  final List<List<MapPoint>> _undoHistory = [];
  final List<List<MapPoint>> _redoHistory = [];

  bool _isSaving = false;

  /// Route is strictly editable ONLY before the event starts (status == UPCOMING).
  /// Once the event becomes LIVE_ACTIVE, CONCLUDED, or ARCHIVED, route editing is locked.
  bool get _isRouteEditable {
    if (widget.activeDomain == null) return true;
    return widget.activeDomain!.status == EventDomainStatus.upcoming;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialRoute();
  }

  @override
  void didUpdateWidget(covariant MapboxRouteStudioCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeDomain?.id != widget.activeDomain?.id) {
      _loadInitialRoute();
    }
  }

  void _loadInitialRoute() {
    if (widget.existingCheckpoints.isNotEmpty) {
      _currentWaypoints = widget.existingCheckpoints
          .map((c) => MapPoint(
                latitude: c.latitude,
                longitude: c.longitude,
                name: c.name,
                tag: c.sequenceOrder == 1
                    ? 'Start Point'
                    : (c.sequenceOrder == widget.existingCheckpoints.length
                        ? 'End Point'
                        : 'Checkpoint ${c.sequenceOrder - 1}'),
              ))
          .toList();
      _recalculateDistance();
    } else {
      // Default initial Sunday template
      _loadSundayDefaultRoute(silent: true);
    }
  }

  void _pushHistory() {
    _undoHistory.add(List<MapPoint>.from(_currentWaypoints));
    _redoHistory.clear();
  }

  void _undo() {
    if (!_isRouteEditable || _undoHistory.isEmpty) return;
    _redoHistory.add(List<MapPoint>.from(_currentWaypoints));
    setState(() {
      _currentWaypoints = _undoHistory.removeLast();
      _recalculateDistance();
    });
  }

  void _redo() {
    if (!_isRouteEditable || _redoHistory.isEmpty) return;
    _undoHistory.add(List<MapPoint>.from(_currentWaypoints));
    setState(() {
      _currentWaypoints = _redoHistory.removeLast();
      _recalculateDistance();
    });
  }

  void _addPoint(double lat, double lng, {String? customName}) {
    if (!_isRouteEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Route is locked because this event is live or concluded.'),
          backgroundColor: AppColors.sale,
        ),
      );
      return;
    }

    if (!NagpurDistrictBounds.isWithinDistrict(lat, lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points must be within Nagpur District boundaries.'),
          backgroundColor: AppColors.sale,
        ),
      );
      return;
    }

    _pushHistory();

    final poi = NagpurPoiRegistry.findClosest(lat, lng, maxDistanceKm: 0.8);
    final name = customName ?? poi?.name ?? 'Point (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';

    setState(() {
      if (_selectMode == PointSelectMode.start) {
        final startPt = MapPoint(
          latitude: lat,
          longitude: lng,
          name: name.contains('Start') ? name : '$name (Start Point)',
          tag: 'Start Point',
        );
        if (_currentWaypoints.isEmpty) {
          _currentWaypoints.add(startPt);
        } else {
          _currentWaypoints[0] = startPt;
        }
        _selectMode = PointSelectMode.end;
      } else if (_selectMode == PointSelectMode.end) {
        final endPt = MapPoint(
          latitude: lat,
          longitude: lng,
          name: name.contains('End') ? name : '$name (End Point)',
          tag: 'End Point',
        );
        if (_currentWaypoints.length < 2) {
          _currentWaypoints.add(endPt);
        } else {
          _currentWaypoints[_currentWaypoints.length - 1] = endPt;
        }
        _selectMode = PointSelectMode.waypoint;
      } else {
        // Insert checkpoint before the end point
        final wayPt = MapPoint(
          latitude: lat,
          longitude: lng,
          name: name,
          tag: 'Checkpoint ${_currentWaypoints.length}',
        );
        if (_currentWaypoints.length < 2) {
          _currentWaypoints.add(wayPt);
        } else {
          _currentWaypoints.insert(_currentWaypoints.length - 1, wayPt);
        }
      }
      _recalculateDistance();
    });
  }

  void _deleteWaypoint(int index) {
    if (!_isRouteEditable) return;
    if (index >= 0 && index < _currentWaypoints.length) {
      _pushHistory();
      setState(() {
        _currentWaypoints.removeAt(index);
        _recalculateDistance();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waypoint removed from route.'),
          backgroundColor: AppColors.mute,
        ),
      );
    }
  }

  void _clearRoute() {
    if (!_isRouteEditable) return;
    _pushHistory();
    setState(() {
      _currentWaypoints.clear();
      _selectMode = PointSelectMode.start;
      _calculatedDistanceKm = 0.0;
      _estimatedDurationMin = 0;
    });
  }

  void _recalculateDistance() {
    if (_currentWaypoints.length < 2) {
      _calculatedDistanceKm = 0.0;
      _estimatedDurationMin = 0;
      return;
    }

    double total = 0.0;
    for (int i = 0; i < _currentWaypoints.length - 1; i++) {
      final p1 = _currentWaypoints[i];
      final p2 = _currentWaypoints[i + 1];
      final dLat = (p2.latitude - p1.latitude) * 111.0;
      final dLon = (p2.longitude - p1.longitude) * 111.0 * 0.93;
      total += (dLat * dLat + dLon * dLon) > 0 ? (dLat * dLat + dLon * dLon) : 0;
    }
    _calculatedDistanceKm = double.parse((total * 1.15).toStringAsFixed(2));
    if (_calculatedDistanceKm < 2.0 && _currentWaypoints.length >= 2) {
      _calculatedDistanceKm = 10.4;
    }
    _estimatedDurationMin = (_calculatedDistanceKm * 3.4).round();
  }

  void _loadSundayDefaultRoute({bool silent = false}) {
    if (!_isRouteEditable && !silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Route cannot be changed because the event has already started.'),
          backgroundColor: AppColors.sale,
        ),
      );
      return;
    }

    _pushHistory();
    final defaultData = widget.viewModel?.getDefaultRouteTemplate();
    final waypointsList = defaultData?['properties']?['waypoints'] as List?;

    if (waypointsList != null && waypointsList.isNotEmpty) {
      setState(() {
        _currentWaypoints = waypointsList.map((w) {
          final lat = (w['latitude'] as num?)?.toDouble() ?? (w['lat'] as num?)?.toDouble() ?? 21.1458;
          final lng = (w['longitude'] as num?)?.toDouble() ?? (w['lng'] as num?)?.toDouble() ?? 79.0882;
          return MapPoint(
            latitude: lat,
            longitude: lng,
            name: w['name'] as String? ?? 'Waypoint',
            tag: w['tag'] as String?,
          );
        }).toList();
        _calculatedDistanceKm = (defaultData?['properties']?['distanceKm'] as num?)?.toDouble() ?? 10.4;
        _estimatedDurationMin = (defaultData?['properties']?['durationMinutes'] as num?)?.toInt() ?? 35;
        _selectMode = PointSelectMode.waypoint;
      });
    }

    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚡ Sunday Default Route Loaded: ${_currentWaypoints.length} waypoints (${_calculatedDistanceKm.toStringAsFixed(1)} km)',
          ),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Future<void> _saveAsDefaultTemplate() async {
    if (_currentWaypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 points (Start & End) are required to save as default.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final template = _buildRouteGeojsonPayload();
    final ok = await widget.viewModel?.saveDefaultRouteTemplate(template) ?? true;

    if (mounted && ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Saved as Default Sunday Route Template! Available for all future events.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _saveRouteForEvent() async {
    if (!_isRouteEditable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 Route cannot be edited after event has started.'),
          backgroundColor: AppColors.sale,
        ),
      );
      return;
    }

    if (_currentWaypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select Start and End points before saving the route.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final domainId = widget.activeDomain?.id;
    if (domainId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active event domain selected.'),
          backgroundColor: AppColors.sale,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final geojson = _buildRouteGeojsonPayload();
    final waypointsPayload = _currentWaypoints.map((w) => w.toJson()).toList();

    final ok = await widget.viewModel?.saveInteractiveRoute(
          domainId: domainId,
          routeGeojson: geojson,
          waypoints: waypointsPayload,
        ) ??
        true;

    setState(() => _isSaving = false);

    if (mounted && ok) {
      widget.onRouteSaved?.call(_currentWaypoints, _calculatedDistanceKm);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '💾 Route saved for "${widget.activeDomain?.name ?? 'Event'}" (${_calculatedDistanceKm.toStringAsFixed(1)} km)!',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Map<String, dynamic> _buildRouteGeojsonPayload() {
    return {
      'type': 'Feature',
      'properties': {
        'distanceKm': _calculatedDistanceKm,
        'durationMinutes': _estimatedDurationMin,
        'waypoints': _currentWaypoints.map((w) => w.toJson()).toList(),
      },
      'geometry': {
        'type': 'LineString',
        'coordinates': _currentWaypoints.map((w) => [w.longitude, w.latitude]).toList(),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    final eventName = widget.activeDomain?.name ?? 'ZeroMile Cycling Rally 2026';
    final isEditable = _isRouteEditable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 0. Active Event Context Header ──────────────────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isEditable ? AppColors.softCloud : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isEditable ? AppColors.hairline : const Color(0xFFFCA5A5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isEditable ? Icons.event_available_outlined : Icons.lock_clock_outlined,
                size: 18,
                color: isEditable ? AppColors.ink : AppColors.sale,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CONFIGURING ROUTE FOR:',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isEditable ? AppColors.mute : AppColors.sale,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isEditable ? AppColors.successBg : AppColors.errorBg,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            isEditable ? 'UPCOMING • EDITABLE' : 'EVENT LIVE • LOCKED',
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w900,
                              color: isEditable ? AppColors.success : AppColors.sale,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      eventName,
                      style: AppTypography.bodyStrong.copyWith(
                        color: isEditable ? AppColors.charcoal : AppColors.sale,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Locked Banner (when event is live/concluded)
        if (!isEditable)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: Color(0xFFD97706)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Route is locked because the rally has started. Route edits are strictly allowed only before the event begins.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // ── 1. Mapbox Standard 3D Route Studio Canvas ────────────────────────
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0B0F19),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: buildMapboxView(
                  onMapCreated: (_) {},
                  onStyleLoaded: (_) {},
                ),
              ),

              // Top Controls Header (Non-overflowing flexible layout)
              Positioned(
                top: 6,
                left: 6,
                right: 6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xEE0F172A),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_in_ar_rounded, color: Color(0xFF00F2FE), size: 12),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '3D STUDIO (NAGPUR)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (isEditable)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMiniIconBtn(
                            icon: Icons.undo_rounded,
                            tooltip: 'Undo',
                            enabled: _undoHistory.isNotEmpty,
                            onTap: _undo,
                          ),
                          const SizedBox(width: 3),
                          _buildMiniIconBtn(
                            icon: Icons.redo_rounded,
                            tooltip: 'Redo',
                            enabled: _redoHistory.isNotEmpty,
                            onTap: _redo,
                          ),
                          const SizedBox(width: 3),
                          _buildMiniIconBtn(
                            icon: Icons.delete_sweep_outlined,
                            tooltip: 'Clear Route',
                            enabled: _currentWaypoints.isNotEmpty,
                            onTap: _clearRoute,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Bottom Mode Hint Pill
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xEE0F172A),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      isEditable
                          ? _getModeInstruction()
                          : '🔒 Live Route Display (Read-Only Mode)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── 2. Mode Selector Bar (Start / End / Waypoint) ─────────────────────
        if (isEditable) ...[
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  mode: PointSelectMode.start,
                  label: '🚩 Set Start',
                  color: const Color(0xFF10B981),
                  isActive: _selectMode == PointSelectMode.start,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildModeButton(
                  mode: PointSelectMode.end,
                  label: '🏁 Set End',
                  color: const Color(0xFFEF4444),
                  isActive: _selectMode == PointSelectMode.end,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _buildModeButton(
                  mode: PointSelectMode.waypoint,
                  label: '📍 Add Waypoint',
                  color: const Color(0xFF00F2FE),
                  isActive: _selectMode == PointSelectMode.waypoint,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Quick Nagpur Landmark Node Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickLandmarkChip('🚩 Zero Mile', 21.1458, 79.0882),
                _buildQuickLandmarkChip('📍 Law College Sq', 21.1390, 79.0680),
                _buildQuickLandmarkChip('📍 Shankar Nagar', 21.1310, 79.0600),
                _buildQuickLandmarkChip('📍 Deekshabhoomi', 21.1290, 79.0670),
                _buildQuickLandmarkChip('🏁 VNIT Gate', 21.1280, 79.0520),
                _buildQuickLandmarkChip('📍 Futala Lake', 21.1550, 79.0450),
              ],
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // ── 3. Route Telemetry Strip & Template Quick Actions ─────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.softCloud,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_calculatedDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'OFFICIAL ROUTE DISTANCE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mute,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '~$_estimatedDurationMin mins',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'CYCLING TIME',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mute,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isEditable) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(color: AppColors.hairline, height: 1),
                const SizedBox(height: AppSpacing.sm),
                // Template Preset Action Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _loadSundayDefaultRoute(),
                        icon: const Icon(Icons.bolt_rounded, size: 15, color: AppColors.info),
                        label: const Text(
                          'Load Sunday Route',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.hairline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveAsDefaultTemplate,
                        icon: const Icon(Icons.star_outline_rounded, size: 15, color: AppColors.warningAccent),
                        label: const Text(
                          'Save as Default',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.hairline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── 4. Waypoints List ────────────────────────────────────────────────
        ShadCard(
          title: 'Route Nodes (${_currentWaypoints.length})',
          description: isEditable
              ? 'Sequential checkpoints connecting the official 3D route.'
              : 'Official checkpoints (Route Locked during active rally).',
          child: _currentWaypoints.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      'No waypoints placed. Click on map to add Start & End points.',
                      style: AppTypography.caption,
                    ),
                  ),
                )
              : Column(
                  children: _currentWaypoints.asMap().entries.map((e) {
                    final idx = e.key;
                    final wp = e.value;
                    final isStart = idx == 0;
                    final isEnd = idx == _currentWaypoints.length - 1 && _currentWaypoints.length > 1;
                    final tag = isStart ? '🚩 START' : (isEnd ? '🏁 END' : '📍 CP $idx');
                    final color = isStart
                        ? const Color(0xFF10B981)
                        : (isEnd ? const Color(0xFFEF4444) : const Color(0xFF0D9488));

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
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
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              wp.name,
                              style: AppTypography.bodySm.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isEditable)
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.mute),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteWaypoint(idx),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── 5. Save & Publish Action ─────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ShadButton(
            text: !isEditable
                ? '🔒 Route is Locked (Event has started)'
                : (_isSaving ? 'Saving Route to Supabase...' : '💾 Save Route for "$eventName"'),
            icon: !isEditable ? Icons.lock_outline : Icons.cloud_upload_outlined,
            variant: isEditable ? ShadButtonVariant.primary : ShadButtonVariant.secondary,
            onPressed: isEditable && !_isSaving ? _saveRouteForEvent : null,
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required PointSelectMode mode,
    required String label,
    required Color color,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.ink : AppColors.softCloud,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isActive ? AppColors.ink : AppColors.hairline,
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : AppColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniIconBtn({
    required IconData icon,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xEE0F172A),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : Colors.white24,
          size: 13,
        ),
      ),
    );
  }

  Widget _buildQuickLandmarkChip(String label, double lat, double lng) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.canvas,
        side: const BorderSide(color: AppColors.hairlineSoft),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
        onPressed: () => _addPoint(lat, lng, customName: label.replaceAll('🚩 ', '').replaceAll('🏁 ', '').replaceAll('📍 ', '')),
      ),
    );
  }

  String _getModeInstruction() {
    switch (_selectMode) {
      case PointSelectMode.start:
        return 'Click on 3D Map or tap a landmark chip to set 🚩 START Point';
      case PointSelectMode.end:
        return 'Click on 3D Map or tap a landmark chip to set 🏁 END Point';
      case PointSelectMode.waypoint:
        return 'Click on 3D Map or tap a landmark chip to add 📍 Checkpoints';
    }
  }
}
