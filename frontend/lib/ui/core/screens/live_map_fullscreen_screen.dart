// lib/ui/core/screens/live_map_fullscreen_screen.dart
//
// Full-screen live map screen — shared by Participant, Group Leader, and Super Admin.
// Uses real Mapbox Standard 3D style (pitch 55°, bearing 15°, Nagpur centred).
// Role-specific overlays are layered as Positioned widgets over the map.
//
// Map aesthetic: ported from map-ui-idea — 3-layer radium glowing route,
// glowing rider dots with callout banners, Mapbox Standard 3D buildings.

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../models/user_live_location.dart';
import '../../../models/route_checkpoint.dart';
import '../../../models/sos_event.dart';
import '../../../logic/view_models/map_test_mode_notifier.dart';
import '../../core/dialogs/emergency_sos_modal.dart';
import '../../core/widgets/route_tracking_bottom_sheet.dart';
import '../widgets/map_view_platform/map_view_platform.dart';

// ─── Nagpur Centre ───────────────────────────────────────────────────────────
const _kNagpurLng = 79.0882;
const _kNagpurLat = 21.1458;

// ─── Simulated Demo Rider Data ───────────────────────────────────────────────
const _kSimRiders = [
  {'id': 'sim-0', 'name': 'Rajesh Sharma', 'isLeader': true},
  {'id': 'sim-1', 'name': 'Aniket Deshmukh', 'isLeader': false},
  {'id': 'sim-2', 'name': 'Priya Verma', 'isLeader': false},
  {'id': 'sim-3', 'name': 'Saurabh Joshi', 'isLeader': false},
];

// ─── Role Enum ───────────────────────────────────────────────────────────────
enum LiveMapRole { participant, leader, superAdmin }

// ─── Cluster Tier ────────────────────────────────────────────────────────────
enum _ClusterTier { individual, skyBlue, amber, coralRed }

_ClusterTier _clusterTier(int count) {
  if (count >= 100) return _ClusterTier.coralRed;
  if (count >= 25) return _ClusterTier.amber;
  if (count >= 5) return _ClusterTier.skyBlue;
  return _ClusterTier.individual;
}

Color _clusterColor(_ClusterTier tier) {
  switch (tier) {
    case _ClusterTier.skyBlue:
      return AppColors.clusterSkyBlue;
    case _ClusterTier.amber:
      return AppColors.clusterAmber;
    case _ClusterTier.coralRed:
      return AppColors.clusterCoralRed;
    case _ClusterTier.individual:
      return AppColors.clusterCyan;
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class LiveMapFullscreenScreen extends StatefulWidget {
  final LiveMapRole role;
  final List<UserLiveLocation> liveLocations;
  final List<RouteCheckpoint> checkpoints;

  /// For participant SOS — receives EmergencyType from EmergencySosModal
  final String? currentUserId;
  final String? domainId;
  final Future<bool> Function(String userId, String domainId, EmergencyType type)?
      onSosTrigger;

  /// For RouteTrackingBottomSheet (participant only)
  final int activeCheckpointIndex;
  final double distanceRemainingKm;
  final String estimatedArrivalTime;

  /// For stats FAB slide-up (leader / admin)
  final Widget? statsSheetContent;

  const LiveMapFullscreenScreen({
    super.key,
    required this.role,
    this.liveLocations = const [],
    this.checkpoints = const [],
    this.currentUserId,
    this.domainId,
    this.onSosTrigger,
    this.activeCheckpointIndex = 0,
    this.distanceRemainingKm = 0,
    this.estimatedArrivalTime = '--:--',
    this.statsSheetContent,
  });

  @override
  State<LiveMapFullscreenScreen> createState() =>
      _LiveMapFullscreenScreenState();
}

class _GeoCoord {
  final double lat;
  final double lng;
  const _GeoCoord(this.lat, this.lng);
}

class _LiveMapFullscreenScreenState extends State<LiveMapFullscreenScreen>
    with TickerProviderStateMixin {
  dynamic _mapInstance;

  // Simulated rider state
  List<UserLiveLocation> _simRiders = [];
  List<_GeoCoord> _routePositions = [];
  int _simIndex = 0;
  Timer? _simTimer;

  // Stats panel animation
  late AnimationController _statsAnim;
  late Animation<double> _statsSlide;
  bool _statsOpen = false;

  // Pulse ring animation for dense clusters
  late AnimationController _pulseAnim;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      initPlatformMapbox();
    }

    _statsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _statsSlide = CurvedAnimation(parent: _statsAnim, curve: Curves.easeOutCubic);

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _statsAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  // ── Map init ──────────────────────────────────────────────────────────────
  void _onMapCreated(dynamic map) {
    if (kIsWeb) return;
    _mapInstance = map;
  }

  void _onStyleLoaded(dynamic _) async {
    if (kIsWeb) return;
    await _addRouteLayer();
    setState(() {});
  }

  // ── Route layer ───────────────────────────────────────────────────────────
  Future<void> _addRouteLayer() async {
    if (widget.checkpoints.length >= 2) {
      _routePositions = widget.checkpoints
          .map((cp) => _GeoCoord(cp.latitude, cp.longitude))
          .toList();
    } else {
      // Default sample Nagpur route coordinates for simulation
      _routePositions = const [
        _GeoCoord(21.1458, 79.0882),
        _GeoCoord(21.1410, 79.0750),
        _GeoCoord(21.1310, 79.0600),
        _GeoCoord(21.1290, 79.0670),
        _GeoCoord(21.1280, 79.0520),
      ];
    }

    if (!kIsWeb && _mapInstance != null) {
      await updatePlatformRouteLayer(_mapInstance, widget.checkpoints);
    }
  }

  // ── Simulation engine ─────────────────────────────────────────────────────
  void _startSimulation() {
    if (_routePositions.isEmpty) return;
    _simIndex = 0;
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (!mounted) return;

      if (_simIndex >= _routePositions.length + 15) {
        _simTimer?.cancel();
        setState(() => _simRiders = []);
        return;
      }

      final riders = <UserLiveLocation>[];
      final offsets = [0, -4, -8, -12];
      for (int i = 0; i < _kSimRiders.length; i++) {
        int idx = _simIndex + offsets[i];
        idx = idx.clamp(0, _routePositions.length - 1);
        final pos = _routePositions[idx];
        riders.add(UserLiveLocation(
          id: _kSimRiders[i]['id'] as String,
          domainId: widget.domainId ?? 'demo',
          userId: _kSimRiders[i]['id'] as String,
          latitude: pos.lat.toDouble(),
          longitude: pos.lng.toDouble(),
          speedKmh: 18.5 + i * 2.0,
          heading: 215,
          updatedAt: DateTime.now(),
          userName: _kSimRiders[i]['name'] as String,
        ));
      }

      setState(() {
        _simRiders = riders;
        _simIndex += 2;
      });
    });
  }

  void _stopSimulation() {
    _simTimer?.cancel();
    setState(() => _simRiders = []);
  }

  // ── Effective rider list ──────────────────────────────────────────────────
  List<UserLiveLocation> get _effectiveRiders {
    final real = widget.liveLocations;
    final testMode =
        context.watch<MapTestModeNotifier?>()?.isTestMode ?? false;
    if (testMode && _simRiders.isNotEmpty) {
      return [...real, ..._simRiders];
    }
    return real;
  }

  // ── Clustering (SuperAdmin only) ──────────────────────────────────────────
  List<_RiderCluster> _buildClusters(List<UserLiveLocation> riders) {
    const double clusterRadiusDeg = 0.0005; // ~50 m
    final used = List<bool>.filled(riders.length, false);
    final clusters = <_RiderCluster>[];

    for (int i = 0; i < riders.length; i++) {
      if (used[i]) continue;
      final group = [riders[i]];
      used[i] = true;

      for (int j = i + 1; j < riders.length; j++) {
        if (used[j]) continue;
        final dlat = (riders[j].latitude - riders[i].latitude).abs();
        final dlng = (riders[j].longitude - riders[i].longitude).abs();
        if (dlat < clusterRadiusDeg && dlng < clusterRadiusDeg) {
          group.add(riders[j]);
          used[j] = true;
        }
      }

      final avgLat = group.map((r) => r.latitude).reduce((a, b) => a + b) /
          group.length;
      final avgLng = group.map((r) => r.longitude).reduce((a, b) => a + b) /
          group.length;

      clusters.add(_RiderCluster(
        count: group.length,
        latitude: avgLat,
        longitude: avgLng,
        riders: group,
      ));
    }
    return clusters;
  }

  /// Screen to map coordinate projection (approximate for overlay)
  Offset _latLngToScreen(double lat, double lng, Size size) {
    const double centerLat = _kNagpurLat;
    const double centerLng = _kNagpurLng;
    const double scaleFactor = 3800.0 * 1.0; // matches zoom ~14.8

    final dx = (lng - centerLng) * scaleFactor;
    final dy = -(lat - centerLat) * scaleFactor;
    return Offset(size.width / 2 + dx, size.height / 2 + dy);
  }

  // ── Stats panel ───────────────────────────────────────────────────────────
  void _toggleStats() {
    setState(() => _statsOpen = !_statsOpen);
    _statsOpen ? _statsAnim.forward() : _statsAnim.reverse();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final size = MediaQuery.of(context).size;
    final testMode =
        context.watch<MapTestModeNotifier?>()?.isTestMode ?? false;

    // Trigger / stop simulation based on test mode state
    if (testMode && _simRiders.isEmpty && _simTimer == null && _routePositions.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSimulation());
    } else if (!testMode && (_simTimer?.isActive ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _stopSimulation());
    }

    final riders = _effectiveRiders;
    final clusters = widget.role == LiveMapRole.superAdmin
        ? _buildClusters(riders)
        : null;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 1. Full-bleed Mapbox 3D map ────────────────────────────────
          Positioned.fill(
            child: buildMapboxView(
              onMapCreated: _onMapCreated,
              onStyleLoaded: _onStyleLoaded,
            ),
          ),

          // ── 2. Rider dots overlay (CustomPaint over map) ───────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (ctx, _) => CustomPaint(
                painter: _RiderOverlayPainter(
                  pulseFraction: _pulseAnim.value,
                  riders: clusters == null ? riders : [],
                  clusters: clusters ?? [],
                  role: widget.role,
                  mapSize: size,
                  latLngToScreen: _latLngToScreen,
                ),
              ),
            ),
          ),

          // ── 3. Top-left: LIVE chip ────────────────────────────────────
          Positioned(
            top: safeTop + 14,
            left: AppSpacing.md,
            child: _buildLiveChip(riders.length),
          ),

          // ── 4. Top-left below chip: compact member strip (P + L) ──────
          if (widget.role != LiveMapRole.superAdmin)
            Positioned(
              top: safeTop + 56,
              left: AppSpacing.md,
              child: _buildMemberStrip(riders),
            ),

          // ── 5. Top-right: SOS button (participant only) ────────────────
          if (widget.role == LiveMapRole.participant)
            Positioned(
              top: safeTop + 12,
              right: AppSpacing.md,
              child: _buildSosButton(context),
            ),

          // ── 6. Bottom-left: density legend (superadmin only) ──────────
          if (widget.role == LiveMapRole.superAdmin)
            Positioned(
              left: AppSpacing.md,
              bottom: 108,
              child: _buildDensityLegend(),
            ),

          // ── 7. Bottom-right: Stats FAB (leader + admin) ───────────────
          if (widget.role != LiveMapRole.participant)
            Positioned(
              right: AppSpacing.md,
              bottom: 108,
              child: GestureDetector(
                onTap: _toggleStats,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xEE0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    _statsOpen
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),

          // ── 8. Stats slide-up sheet (leader + admin) ──────────────────
          if (widget.role != LiveMapRole.participant &&
              widget.statsSheetContent != null)
            AnimatedBuilder(
              animation: _statsSlide,
              builder: (ctx, child) => Positioned(
                left: 0,
                right: 0,
                bottom: _statsOpen ? 0 : -(size.height * 0.45),
                child: child!,
              ),
              child: _buildStatsSheet(context),
            ),

          // ── 9. Bottom: RouteTrackingBottomSheet (participant only) ─────
          if (widget.role == LiveMapRole.participant &&
              widget.checkpoints.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RouteTrackingBottomSheet(
                checkpoints: widget.checkpoints,
                activeCheckpointIndex: widget.activeCheckpointIndex,
                distanceRemainingKm: widget.distanceRemainingKm,
                estimatedArrivalTime: widget.estimatedArrivalTime,
                nextCheckpointName: widget.checkpoints.length > 1
                    ? widget.checkpoints[widget.activeCheckpointIndex
                            .clamp(0, widget.checkpoints.length - 1)]
                        .name
                    : '',
              ),
            ),

          // ── 10. Test Mode amber banner (when active) ──────────────────
          if (testMode)
            Positioned(
              bottom: widget.role == LiveMapRole.participant ? 160 : 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xEEF59E0B),
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.science_outlined,
                          color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'TEST MODE — Simulated Riders Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Widget Builders ────────────────────────────────────────────────────────

  Widget _buildLiveChip(int riderCount) {
    final roleLabel = switch (widget.role) {
      LiveMapRole.participant => 'Your Group',
      LiveMapRole.leader => 'Team',
      LiveMapRole.superAdmin => 'All Riders',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xEE0F172A),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF00FF66),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'LIVE  •  $roleLabel  •  $riderCount Online',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStrip(List<UserLiveLocation> riders) {
    const maxVisible = 5;
    final visible = riders.take(maxVisible).toList();
    final overflow = max(0, riders.length - maxVisible);

    if (riders.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEE0F172A),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...visible.asMap().entries.map((e) {
            final isLeader = e.value.id.startsWith('sim-0') ||
                (widget.role == LiveMapRole.leader && e.key == 0);
            final color = isLeader
                ? const Color(0xFFFF9100)
                : [
                    const Color(0xFF00F2FE),
                    const Color(0xFF00FF66),
                    const Color(0xFF2979FF),
                    const Color(0xFF00F2FE),
                  ][e.key % 4];
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: e.value.userName ?? 'Rider ${e.key + 1}',
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      (e.value.userName ?? 'R').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          if (overflow > 0)
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '+$overflow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSosButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onSosTrigger == null) return;
        EmergencySosModal.show(
          context,
          onTrigger: (type) async {
            final ok = await widget.onSosTrigger!(
              widget.currentUserId ?? '',
              widget.domainId ?? '',
              type,
            );
            if (context.mounted && ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Emergency SOS dispatched to Command Center & Marshals.'),
                  backgroundColor: AppColors.sale,
                ),
              );
            }
          },
        );
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
            Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 15),
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
    );
  }

  Widget _buildDensityLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xEE0F172A),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendDot(AppColors.clusterCyan, '1-4'),
          const SizedBox(width: 8),
          _legendDot(AppColors.clusterSkyBlue, '5-24'),
          const SizedBox(width: 8),
          _legendDot(AppColors.clusterAmber, '25-99'),
          const SizedBox(width: 8),
          _legendDot(AppColors.clusterCoralRed, '100+'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStatsSheet(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
      decoration: const BoxDecoration(
        color: Color(0xF20F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
            top: BorderSide(color: Color(0x33FFFFFF), width: 1.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          if (widget.statsSheetContent != null)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: widget.statsSheetContent!,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Rider/Cluster Overlay Painter ──────────────────────────────────────────
class _RiderCluster {
  final int count;
  final double latitude;
  final double longitude;
  final List<UserLiveLocation> riders;

  const _RiderCluster({
    required this.count,
    required this.latitude,
    required this.longitude,
    required this.riders,
  });
}

class _RiderOverlayPainter extends CustomPainter {
  final double pulseFraction;
  final List<UserLiveLocation> riders;
  final List<_RiderCluster> clusters;
  final LiveMapRole role;
  final ui.Size mapSize;
  final Offset Function(double lat, double lng, Size size) latLngToScreen;

  const _RiderOverlayPainter({
    required this.pulseFraction,
    required this.riders,
    required this.clusters,
    required this.role,
    required this.mapSize,
    required this.latLngToScreen,
  });

  static const _riderColors = [
    Color(0xFFFF9100), // leader amber
    Color(0xFF00F2FE), // cyan
    Color(0xFF00FF66), // radium green
    Color(0xFF2979FF), // electric blue
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (role == LiveMapRole.superAdmin) {
      _drawClusters(canvas, size);
    } else {
      _drawIndividualRiders(canvas, size);
    }
  }

  void _drawIndividualRiders(Canvas canvas, Size size) {
    for (int idx = 0; idx < riders.length; idx++) {
      final rider = riders[idx];
      final isLeader = idx == 0 || rider.id == 'sim-0';
      final color = _riderColors[idx % _riderColors.length];
      final pos = latLngToScreen(rider.latitude, rider.longitude, size);

      // Animated halo
      final haloPaint = Paint()
        ..color = color.withOpacity(0.35 + pulseFraction * 0.25)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
      canvas.drawCircle(pos, (isLeader ? 14.0 : 10.0) + pulseFraction * 3, haloPaint);

      // Core dot
      canvas.drawCircle(pos, isLeader ? 7.0 : 5.0,
          Paint()..color = color..style = PaintingStyle.fill);
      canvas.drawCircle(pos, isLeader ? 7.0 : 5.0,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke);

      // Callout banner
      final name = isLeader
          ? '${rider.userName ?? "Leader"} ★'
          : (rider.userName ?? 'Rider ${idx + 1}');
      _drawCallout(canvas, pos, name, color, below: true);
    }
  }

  void _drawClusters(Canvas canvas, Size size) {
    for (final cluster in clusters) {
      final pos = latLngToScreen(cluster.latitude, cluster.longitude, size);
      final tier = _clusterTier(cluster.count);

      if (tier == _ClusterTier.individual) {
        // Draw individual dots for each rider in the cluster
        for (int i = 0; i < cluster.riders.length; i++) {
          final r = cluster.riders[i];
          final rPos = latLngToScreen(r.latitude, r.longitude, size);
          final color = _riderColors[i % _riderColors.length];
          final halo = Paint()
            ..color = color.withOpacity(0.35 + pulseFraction * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(rPos, 9 + pulseFraction * 2, halo);
          canvas.drawCircle(rPos, 5.5, Paint()..color = color);
          canvas.drawCircle(rPos, 5.5,
              Paint()
                ..color = Colors.white
                ..strokeWidth = 1.5
                ..style = PaintingStyle.stroke);
        }
      } else {
        final color = _clusterColor(tier);
        final radius = tier == _ClusterTier.coralRed ? 22.0 : 18.0;

        // Pulse ring for dense clusters
        if (tier == _ClusterTier.coralRed) {
          canvas.drawCircle(
            pos,
            radius + 8 + pulseFraction * 8,
            Paint()
              ..color = color.withOpacity(0.2 + pulseFraction * 0.2)
              ..style = PaintingStyle.fill
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
          );
        }

        // Cluster fill
        canvas.drawCircle(pos, radius,
            Paint()..color = color.withOpacity(0.85)..style = PaintingStyle.fill);
        canvas.drawCircle(pos, radius,
            Paint()
              ..color = Colors.white.withOpacity(0.4)
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke);

        // Count badge
        final tp = TextPainter(
          text: TextSpan(
            text: '${cluster.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas,
            Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
      }
    }
  }

  void _drawCallout(
      Canvas canvas, Offset pos, String text, Color color,
      {bool below = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.0,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final yOffset = below ? 14.0 : -16.0;
    final bgRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + yOffset),
      width: tp.width + 10,
      height: tp.height + 4,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = const Color(0xEE0B0F19),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()
        ..color = color.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    tp.paint(canvas, Offset(bgRect.left + 5, bgRect.top + 2));
  }

  @override
  bool shouldRepaint(covariant _RiderOverlayPainter old) =>
      old.pulseFraction != pulseFraction ||
      old.riders != riders ||
      old.clusters != clusters;
}
