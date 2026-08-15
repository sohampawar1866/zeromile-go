// lib/ui/core/widgets/density_cluster_map_view.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../models/route_checkpoint.dart';
import '../../../models/user_live_location.dart';
import '../../../services/mapbox_service.dart';

enum MapLightingMode { dawn, day, dusk, night }
enum RoutePointMode { start, end, waypoint }

class DensityClusterMapView extends StatefulWidget {
  final String title;
  final bool showHeader;
  final bool showControls;
  final bool isInteractiveRouteBuilder;
  final List<RouteCheckpoint>? checkpoints;
  final List<UserLiveLocation>? liveLocations;
  final Map<String, dynamic>? routeGeojson;
  final ValueChanged<List<MapPoint>>? onWaypointsChanged;
  final ValueChanged<double>? onDistanceCalculated;

  const DensityClusterMapView({
    super.key,
    required this.title,
    this.showHeader = true,
    this.showControls = true,
    this.isInteractiveRouteBuilder = false,
    this.checkpoints,
    this.liveLocations,
    this.routeGeojson,
    this.onWaypointsChanged,
    this.onDistanceCalculated,
  });

  @override
  State<DensityClusterMapView> createState() => _DensityClusterMapViewState();
}

class _DensityClusterMapViewState extends State<DensityClusterMapView>
    with SingleTickerProviderStateMixin {
  late final MapboxService _mapboxService;
  late final AnimationController _pulseCtrl;

  // Map Navigation & Transformation State
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  double _pitchAngle = 0.0; // 0.0 for 2D, 0.45 for 3D tilt
  double _bearingRadians = 0.0; // Camera rotation in radians
  MapLightingMode _lightingMode = MapLightingMode.day;
  RoutePointMode _selectionMode = RoutePointMode.start;

  // Real Dynamic Route Geometry & Waypoints
  List<MapPoint> _waypoints = [];
  final List<MapPoint> _customViaPoints = [];
  List<MapPoint> _routeCoordinates = [];
  double _totalDistanceKm = 0.0;

  // Undo / Redo History Stacks
  final List<String> _historyStack = [];
  final List<String> _redoStack = [];

  // Search Engine State
  final TextEditingController _searchCtrl = TextEditingController();
  List<MapboxSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  // Multi-Rider Simulation State
  bool _isSimulating = false;
  Timer? _simTimer;
  int _simIndex = 0;
  final List<UserLiveLocation> _simulatedRiders = [];

  @override
  void initState() {
    super.initState();
    _mapboxService = MapboxService();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _initInitialRoute();
  }

  void _initInitialRoute() {
    if (widget.checkpoints != null && widget.checkpoints!.isNotEmpty) {
      _waypoints = widget.checkpoints!
          .map((cp) => MapPoint(
                latitude: cp.latitude,
                longitude: cp.longitude,
                name: cp.name,
                tag: cp.checkpointType.name.toUpperCase(),
              ))
          .toList();
    } else {
      _waypoints = const [
        MapPoint(
          latitude: 21.1458,
          longitude: 79.0882,
          name: 'Zero Mile Freedom Park (Start)',
          tag: 'START',
        ),
        MapPoint(
          latitude: 21.1465,
          longitude: 79.0800,
          name: 'Samvidhan Square (Water Point)',
          tag: 'CHECKPOINT',
        ),
        MapPoint(
          latitude: 21.1378,
          longitude: 79.0682,
          name: 'Shankar Nagar Sq (Hydration)',
          tag: 'CHECKPOINT',
        ),
        MapPoint(
          latitude: 21.1290,
          longitude: 79.0670,
          name: 'Deekshabhoomi Stupa (Finish Line)',
          tag: 'FINISH',
        ),
      ];
    }

    _fetchRouteGeometry();
  }

  @override
  void didUpdateWidget(covariant DensityClusterMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checkpoints != oldWidget.checkpoints &&
        widget.checkpoints != null &&
        widget.checkpoints!.isNotEmpty) {
      _waypoints = widget.checkpoints!
          .map((cp) => MapPoint(
                latitude: cp.latitude,
                longitude: cp.longitude,
                name: cp.name,
                tag: cp.checkpointType.name.toUpperCase(),
              ))
          .toList();
      _fetchRouteGeometry();
    }
  }

  Future<void> _fetchRouteGeometry() async {
    if (_waypoints.length < 2) {
      setState(() {
        _routeCoordinates = [];
        _totalDistanceKm = 0.0;
      });
      return;
    }

    final result = await _mapboxService.fetchCyclingRoute(
      _waypoints,
      customViaPoints: _customViaPoints,
    );

    if (mounted) {
      setState(() {
        _routeCoordinates = result.coordinates;
        _totalDistanceKm = result.distanceKm;
      });
      widget.onDistanceCalculated?.call(_totalDistanceKm);
      widget.onWaypointsChanged?.call(_waypoints);
    }
  }

  void _pushHistory() {
    _historyStack.add(
      '${_waypoints.length}:${_customViaPoints.length}:${DateTime.now().millisecondsSinceEpoch}',
    );
    _redoStack.clear();
  }

  void _undoAction() {
    if (_historyStack.isEmpty) return;
    _redoStack.add('${_waypoints.length}:${_customViaPoints.length}');
    _historyStack.removeLast();
    if (_waypoints.length > 2) {
      _waypoints.removeLast();
      _fetchRouteGeometry();
    }
  }

  void _redoAction() {
    if (_redoStack.isEmpty) return;
    _redoStack.removeLast();
    _fetchRouteGeometry();
  }

  void _handleSearch(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await _mapboxService.searchNagpurLocation(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectSearchResult(MapboxSearchResult result) {
    _searchCtrl.clear();
    setState(() => _searchResults = []);

    _pushHistory();
    final newPoint = MapPoint(
      latitude: result.latitude,
      longitude: result.longitude,
      name: result.name,
      tag: _selectionMode == RoutePointMode.start
          ? 'START'
          : _selectionMode == RoutePointMode.end
              ? 'FINISH'
              : 'CHECKPOINT',
    );

    setState(() {
      if (_selectionMode == RoutePointMode.start) {
        if (_waypoints.isEmpty) {
          _waypoints.add(newPoint);
        } else {
          _waypoints[0] = newPoint;
        }
        _selectionMode = RoutePointMode.end;
      } else if (_selectionMode == RoutePointMode.end) {
        if (_waypoints.length < 2) {
          _waypoints.add(newPoint);
        } else {
          _waypoints[_waypoints.length - 1] = newPoint;
        }
        _selectionMode = RoutePointMode.waypoint;
      } else {
        _waypoints.insert(max(1, _waypoints.length - 1), newPoint);
      }
    });

    _fetchRouteGeometry();
  }

  void _toggleSimulation() {
    if (_isSimulating) {
      _stopSimulation();
    } else {
      _startSimulation();
    }
  }

  void _startSimulation() {
    if (_routeCoordinates.isEmpty) return;
    setState(() {
      _isSimulating = true;
      _simIndex = 0;
    });

    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_simIndex >= _routeCoordinates.length + 15) {
        _stopSimulation();
        return;
      }

      final riders = <UserLiveLocation>[];
      final names = [
        'Rajesh Sharma (Leader)',
        'Aniket Deshmukh',
        'Priya Verma',
        'Saurabh Joshi',
      ];
      final offsets = [0, -4, -8, -12];

      for (int i = 0; i < 4; i++) {
        int curIdx = _simIndex + offsets[i];
        if (curIdx < 0) curIdx = 0;
        if (curIdx >= _routeCoordinates.length) curIdx = _routeCoordinates.length - 1;

        final coord = _routeCoordinates[curIdx];
        riders.add(
          UserLiveLocation(
            id: 'sim-rider-$i',
            domainId: 'cycling-2026',
            userId: 'sim-user-$i',
            latitude: coord.latitude,
            longitude: coord.longitude,
            speedKmh: 18.5 + (i * 2.0),
            heading: 215.0,
            userName: names[i],
            updatedAt: DateTime.now(),
          ),
        );
      }

      setState(() {
        _simulatedRiders.clear();
        _simulatedRiders.addAll(riders);
        _simIndex += 2;
      });
    });
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    _simTimer = null;
    if (mounted) {
      setState(() {
        _isSimulating = false;
        _simulatedRiders.clear();
      });
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeRiders = _isSimulating
        ? _simulatedRiders
        : (widget.liveLocations ?? []);

    return Container(
      height: widget.isInteractiveRouteBuilder ? 340 : 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _getMapBgColor(),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.hairlineSoft, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gesture-Driven Interactive Map Canvas
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _zoomScale = (_zoomScale * details.scale).clamp(0.7, 4.0);
                _panOffset += details.focalPointDelta;
              });
            },
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (ctx, _) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _MapboxVector3DPainter(
                    pulseFraction: _pulseCtrl.value,
                    zoomScale: _zoomScale,
                    panOffset: _panOffset,
                    pitchAngle: _pitchAngle,
                    bearingRadians: _bearingRadians,
                    lightingMode: _lightingMode,
                    routeCoordinates: _routeCoordinates,
                    waypoints: _waypoints,
                    riders: activeRiders,
                  ),
                );
              },
            ),
          ),

          // Top Header Overlay
          if (widget.showHeader)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.mapHeaderBg,
                  borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: AppTypography.captionXs.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _totalDistanceKm > 0
                              ? '${_totalDistanceKm.toStringAsFixed(1)} km • Mapbox 3D'
                              : 'Mapbox Standard 3D',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Search Bar (Interactive Route Builder Mode)
          if (widget.isInteractiveRouteBuilder)
            Positioned(
              top: 40,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 15, color: AppColors.mute),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _handleSearch,
                            style: const TextStyle(fontSize: 11, color: AppColors.ink),
                            decoration: const InputDecoration(
                              hintText: 'Search VNIT, YCCE, RCOEM, Sitabuldi...',
                              hintStyle: TextStyle(fontSize: 10.5, color: AppColors.mute),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_isSearching)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.ink),
                          ),
                      ],
                    ),
                  ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.hairlineSoft),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 10),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(4),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairlineSoft),
                        itemBuilder: (ctx, idx) {
                          final res = _searchResults[idx];
                          return InkWell(
                            onTap: () => _selectSearchResult(res),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 13, color: AppColors.ink),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      res.name,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

          // Lighting Mode Widget (Top-Left under header - only for interactive builder)
          if (widget.showControls && widget.isInteractiveRouteBuilder)
            Positioned(
              top: widget.isInteractiveRouteBuilder ? 80 : 42,
              left: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: AppColors.hairlineSoft),
                ),
                child: Row(
                  children: [
                    _buildLightingButton('🌅', MapLightingMode.dawn),
                    _buildLightingButton('☀️', MapLightingMode.day),
                    _buildLightingButton('🌇', MapLightingMode.dusk),
                    _buildLightingButton('🌙', MapLightingMode.night),
                  ],
                ),
              ),
            ),

          // 3D Controls (Right Bottom)
          if (widget.showControls)
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Column(
                children: [
                  _buildMapButton(
                    Icons.undo,
                    _undoAction,
                    tooltip: 'Undo Checkpoint',
                  ),
                  const SizedBox(height: 4),
                  _buildMapButton(
                    Icons.redo,
                    _redoAction,
                    tooltip: 'Redo Checkpoint',
                  ),
                  const SizedBox(height: 4),
                  _buildMapButton(
                    _pitchAngle > 0 ? Icons.layers_clear : Icons.layers,
                    () => setState(() => _pitchAngle = _pitchAngle > 0 ? 0.0 : 0.45),
                    tooltip: 'Toggle 3D Perspective Tilt',
                  ),
                  const SizedBox(height: 4),
                  _buildMapButton(
                    Icons.rotate_right,
                    () => setState(() => _bearingRadians += pi / 4),
                    tooltip: 'Rotate Camera 45°',
                  ),
                  const SizedBox(height: 4),
                  _buildMapButton(
                    Icons.explore,
                    () => setState(() {
                      _bearingRadians = 0.0;
                      _pitchAngle = 0.0;
                      _panOffset = Offset.zero;
                      _zoomScale = 1.0;
                    }),
                    tooltip: 'Reset North Alignment',
                  ),
                  const SizedBox(height: 4),
                  _buildMapButton(
                    _isSimulating ? Icons.pause : Icons.play_arrow,
                    _toggleSimulation,
                    tooltip: 'Multi-Rider 3D Live Simulation',
                    color: _isSimulating ? AppColors.sale : AppColors.ink,
                  ),
                ],
              ),
            ),

          // Density Heatmap Legend (Bottom-Left - only for interactive builder)
          if (widget.showControls && widget.isInteractiveRouteBuilder)
            Positioned(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.mapLegendBg,
                borderRadius: const BorderRadius.all(Radius.circular(AppRadius.sm)),
                border: Border.all(color: AppColors.hairlineSoft),
              ),
              child: const Row(
                children: [
                  _LegendDot(color: AppColors.clusterCyan, label: '1-24'),
                  SizedBox(width: AppSpacing.xs),
                  _LegendDot(color: AppColors.clusterSkyBlue, label: '25-99'),
                  SizedBox(width: AppSpacing.xs),
                  _LegendDot(color: AppColors.clusterAmber, label: '100-299'),
                  SizedBox(width: AppSpacing.xs),
                  _LegendDot(color: AppColors.clusterCoralRed, label: '300+'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingButton(String emoji, MapLightingMode mode) {
    final isSelected = _lightingMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _lightingMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.softCloud : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap, {String? tooltip, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairlineSoft),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 4)],
        ),
        child: Icon(icon, size: 14, color: color ?? AppColors.ink),
      ),
    );
  }

  Color _getMapBgColor() {
    switch (_lightingMode) {
      case MapLightingMode.dawn:
        return const Color(0xFF1E212B);
      case MapLightingMode.dusk:
        return const Color(0xFF1A1A2E);
      case MapLightingMode.night:
        return const Color(0xFF0D111A);
      case MapLightingMode.day:
        return AppColors.mapBackground;
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 8, color: AppColors.charcoal, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// High-Performance 3D Vector Map Painter with Multi-Layer Radium Glowing Polyline
class _MapboxVector3DPainter extends CustomPainter {
  final double pulseFraction;
  final double zoomScale;
  final Offset panOffset;
  final double pitchAngle;
  final double bearingRadians;
  final MapLightingMode lightingMode;
  final List<MapPoint> routeCoordinates;
  final List<MapPoint> waypoints;
  final List<UserLiveLocation> riders;

  _MapboxVector3DPainter({
    required this.pulseFraction,
    required this.zoomScale,
    required this.panOffset,
    required this.pitchAngle,
    required this.bearingRadians,
    required this.lightingMode,
    required this.routeCoordinates,
    required this.waypoints,
    required this.riders,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 3D Perspective & Camera Transforms
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx + panOffset.dx, center.dy + panOffset.dy);
    canvas.scale(zoomScale);
    if (bearingRadians != 0.0) canvas.rotate(bearingRadians);
    if (pitchAngle > 0) {
      final matrix = Matrix4.identity()
        ..setEntry(3, 2, 0.0018)
        ..rotateX(pitchAngle);
      canvas.transform(matrix.storage);
    }
    canvas.translate(-center.dx, -center.dy);

    _drawRoadGrid3D(canvas, size);
    _drawMultiLayerGlowingRoute(canvas, size);
    _drawCheckpointsAndLandmarks(canvas, size);
    _drawLiveRiderMarkers(canvas, size);

    canvas.restore();
  }

  Offset _latLngToScreen(double lat, double lng, Size size) {
    const double centerLat = 21.1458;
    const double centerLng = 79.0882;
    const double scaleFactor = 3800.0;

    final dx = (lng - centerLng) * scaleFactor;
    final dy = -(lat - centerLat) * scaleFactor;

    return Offset(size.width / 2 + dx, size.height / 2 + dy);
  }

  void _drawRoadGrid3D(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = lightingMode == MapLightingMode.night
          ? const Color(0x15FFFFFF)
          : AppColors.streetGrid
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final arterialPaint = Paint()
      ..color = lightingMode == MapLightingMode.night
          ? const Color(0x2A00F2FE)
          : AppColors.streetArterial
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (double x = -size.width; x < size.width * 2; x += 40) {
      canvas.drawLine(Offset(x, -size.height), Offset(x, size.height * 2), gridPaint);
    }
    for (double y = -size.height; y < size.height * 2; y += 40) {
      canvas.drawLine(Offset(-size.width, y), Offset(size.width * 2, y), gridPaint);
    }

    // Main Arterials: Wardha Rd & Amravati Rd
    canvas.drawLine(
      Offset(-size.width, size.height * 0.45),
      Offset(size.width * 2, size.height * 0.45),
      arterialPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.52, -size.height),
      Offset(size.width * 0.52, size.height * 2),
      arterialPaint,
    );
  }

  void _drawMultiLayerGlowingRoute(Canvas canvas, Size size) {
    if (routeCoordinates.isEmpty) return;

    final path = Path();
    final firstPoint = _latLngToScreen(routeCoordinates.first.latitude, routeCoordinates.first.longitude, size);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < routeCoordinates.length; i++) {
      final p = _latLngToScreen(routeCoordinates[i].latitude, routeCoordinates[i].longitude, size);
      path.lineTo(p.dx, p.dy);
    }

    // Layer 1: Ultra-Bright Outer Radium Green Glow (#00FF66)
    final radiumGlowPaint = Paint()
      ..color = const Color(0xE600FF66)
      ..strokeWidth = 22.0 + (pulseFraction * 4.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

    // Layer 2: Vibrant Cyan Mid Glow (#00F2FE)
    final cyanMidPaint = Paint()
      ..color = const Color(0xFF00F2FE)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // Layer 3: Solid Ultra-White Core Polyline (#FFFFFF)
    final whiteCorePaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, radiumGlowPaint);
    canvas.drawPath(path, cyanMidPaint);
    canvas.drawPath(path, whiteCorePaint);
  }

  void _drawCheckpointsAndLandmarks(Canvas canvas, Size size) {
    for (int i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      final pos = _latLngToScreen(wp.latitude, wp.longitude, size);

      final isStart = i == 0;
      final isEnd = i == waypoints.length - 1 && waypoints.length > 1;
      final color = isStart
          ? const Color(0xFF00FF66)
          : isEnd
              ? const Color(0xFFFF1744)
              : const Color(0xFF00F2FE);

      // Outer Radium Halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.45 + pulseFraction * 0.35)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(pos, 14.0 + pulseFraction * 4.0, haloPaint);

      // Core Marker
      final markerPaint = Paint()..color = color..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(pos, 7.0, markerPaint);
      canvas.drawCircle(pos, 7.0, borderPaint);

      // Label with Dark Card Backdrop
      final tp = TextPainter(
        text: TextSpan(
          text: isStart ? '🚩 START' : isEnd ? '🏁 FINISH' : '📍 ${wp.name.split('(').first.trim()}',
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final textRect = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 16),
        width: tp.width + 12,
        height: tp.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(AppRadius.pill)),
        Paint()..color = const Color(0xEE0B0F19),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(textRect, const Radius.circular(AppRadius.pill)),
        Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.0,
      );
      tp.paint(canvas, Offset(textRect.left + 6, textRect.top + 3));
    }
  }

  void _drawLiveRiderMarkers(Canvas canvas, Size size) {
    final riderColors = [
      const Color(0xFFFF9100), // Leader (Amber/Gold)
      const Color(0xFF00F2FE), // Rider 2 (Cyan)
      const Color(0xFF00FF66), // Rider 3 (Radium Green)
      const Color(0xFF2979FF), // Rider 4 (Electric Blue)
    ];

    for (int idx = 0; idx < riders.length; idx++) {
      final rider = riders[idx];
      final color = riderColors[idx % riderColors.length];
      final isLeader = idx == 0;
      final pos = _latLngToScreen(rider.latitude, rider.longitude, size);

      // Rider animated glowing halo
      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.50 + pulseFraction * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(pos, (isLeader ? 14.0 : 10.0) + pulseFraction * 3.0, haloPaint);

      // Rider Core Dot
      final riderPaint = Paint()..color = color..style = PaintingStyle.fill;
      final borderPaint = Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, isLeader ? 7.0 : 5.0, riderPaint);
      canvas.drawCircle(pos, isLeader ? 7.0 : 5.0, borderPaint);

      // Rider Callout Banner
      final tp = TextPainter(
        text: TextSpan(
          text: isLeader ? '👑 ${rider.userName ?? "Rajesh (Leader)"}' : '🚴 ${rider.userName ?? "Rider"}',
          style: TextStyle(
            color: color,
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromCenter(
        center: Offset(pos.dx, pos.dy + 14),
        width: tp.width + 10,
        height: tp.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(AppRadius.sm)),
        Paint()..color = const Color(0xEE0B0F19),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(AppRadius.sm)),
        Paint()..color = color.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 0.8,
      );
      tp.paint(canvas, Offset(bgRect.left + 5, bgRect.top + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _MapboxVector3DPainter old) {
    return old.pulseFraction != pulseFraction ||
        old.zoomScale != zoomScale ||
        old.panOffset != panOffset ||
        old.pitchAngle != pitchAngle ||
        old.bearingRadians != bearingRadians ||
        old.lightingMode != lightingMode ||
        old.routeCoordinates != routeCoordinates ||
        old.riders != riders;
  }
}
