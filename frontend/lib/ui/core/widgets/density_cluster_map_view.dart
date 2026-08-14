// lib/ui/core/widgets/density_cluster_map_view.dart

import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_spacing.dart';
import '../../../config/app_typography.dart';
import '../../../utils/density_cluster_evaluator.dart';

class DensityClusterMapView extends StatefulWidget {
  final String title;
  final bool showHeader;

  const DensityClusterMapView({
    super.key,
    required this.title,
    this.showHeader = true,
  });

  @override
  State<DensityClusterMapView> createState() => _DensityClusterMapViewState();
}

class _DensityClusterMapViewState extends State<DensityClusterMapView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  double _zoomScale = 1.0;
  Offset _panOffset = Offset.zero;
  String _selectedSector = 'ALL';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.mapBackground,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: AppColors.hairlineSoft, width: 1.0),
      ),
      child: Stack(
        children: [
          // Gesture-Driven Interactive Map Canvas
          GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                _zoomScale = (_zoomScale * details.scale).clamp(0.8, 3.5);
                _panOffset += details.focalPointDelta;
              });
            },
            child: AnimatedBuilder(
              animation: _animCtrl,
              builder: (ctx, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _NagpurVectorMapPainter(
                    pulseFraction: _animCtrl.value,
                    zoomScale: _zoomScale,
                    panOffset: _panOffset,
                    selectedSector: _selectedSector,
                  ),
                );
              },
            ),
          ),

          // Header Overlay
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
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Nagpur Live Telemetry',
                          style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Sector Filter Chips
          Positioned(
            top: 42,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSectorChip('ALL', 'All Sectors'),
                  _buildSectorChip('S1', 'Sector 1 (Samvidhan)'),
                  _buildSectorChip('S2', 'Sector 2 (Shankar Nagar)'),
                  _buildSectorChip('S3', 'Sector 3 (Law College)'),
                  _buildSectorChip('S4', 'Sector 4 (Deekshabhoomi)'),
                ],
              ),
            ),
          ),

          // Zoom & Pan Map Controls
          Positioned(
            right: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: Column(
              children: [
                _buildMapButton(Icons.add, () => setState(() => _zoomScale = (_zoomScale + 0.3).clamp(0.8, 3.5))),
                const SizedBox(height: AppSpacing.xs),
                _buildMapButton(Icons.remove, () => setState(() => _zoomScale = (_zoomScale - 0.3).clamp(0.8, 3.5))),
                const SizedBox(height: AppSpacing.xs),
                _buildMapButton(Icons.center_focus_strong, () => setState(() {
                  _zoomScale = 1.0;
                  _panOffset = Offset.zero;
                })),
              ],
            ),
          ),

          // Density Heatmap Tier Legend
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
                  _LegendDot(color: AppColors.clusterCoralRed, label: '300-599'),
                  SizedBox(width: AppSpacing.xs),
                  _LegendDot(color: AppColors.clusterDeepPurple, label: '600+'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectorChip(String sectorId, String label) {
    final isSelected = _selectedSector == sectorId;
    return GestureDetector(
      onTap: () => setState(() => _selectedSector = sectorId),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : AppColors.canvas,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.onPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairlineSoft),
        ),
        child: Icon(icon, size: 14, color: AppColors.ink),
      ),
    );
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

class _NagpurVectorMapPainter extends CustomPainter {
  final double pulseFraction;
  final double zoomScale;
  final Offset panOffset;
  final String selectedSector;

  _NagpurVectorMapPainter({
    required this.pulseFraction,
    required this.zoomScale,
    required this.panOffset,
    required this.selectedSector,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2 + panOffset.dx, size.height / 2 + panOffset.dy);
    canvas.scale(zoomScale);
    canvas.translate(-size.width / 2, -size.height / 2);

    _drawNagpurStreetGrid(canvas, size);
    _drawOfficialRallyRoute(canvas, size);
    _drawDensityHeatmapClusters(canvas, size);
    _drawLandmarkPins(canvas, size);

    canvas.restore();
  }

  void _drawNagpurStreetGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.streetGrid
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final arterialPaint = Paint()
      ..color = AppColors.streetArterial
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    canvas.drawLine(Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), arterialPaint);
    canvas.drawLine(Offset(0, size.height * 0.72), Offset(size.width, size.height * 0.72), arterialPaint);
    canvas.drawLine(Offset(size.width * 0.32, 0), Offset(size.width * 0.32, size.height), arterialPaint);
    canvas.drawLine(Offset(size.width * 0.68, 0), Offset(size.width * 0.68, size.height), arterialPaint);
  }

  void _drawOfficialRallyRoute(Canvas canvas, Size size) {
    final routeGlowPaint = Paint()
      ..color = AppColors.routeGlow
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final routeLinePaint = Paint()
      ..color = AppColors.routeLine
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final p0 = Offset(size.width * 0.20, size.height * 0.30);
    final p1 = Offset(size.width * 0.45, size.height * 0.25);
    final p2 = Offset(size.width * 0.80, size.height * 0.45);
    final p3 = Offset(size.width * 0.75, size.height * 0.75);
    final p4 = Offset(size.width * 0.38, size.height * 0.80);
    final p5 = Offset(size.width * 0.20, size.height * 0.58);

    final path = Path()
      ..moveTo(p0.dx, p0.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p4.dx, p4.dy)
      ..lineTo(p5.dx, p5.dy)
      ..close();

    canvas.drawPath(path, routeGlowPaint);
    canvas.drawPath(path, routeLinePaint);
  }

  void _drawDensityHeatmapClusters(Canvas canvas, Size size) {
    final mockClusters = [
      {'x': size.width * 0.20, 'y': size.height * 0.30, 'count': 450, 'sector': 'S1'},
      {'x': size.width * 0.45, 'y': size.height * 0.25, 'count': 220, 'sector': 'S2'},
      {'x': size.width * 0.80, 'y': size.height * 0.45, 'count': 650, 'sector': 'S3'},
      {'x': size.width * 0.75, 'y': size.height * 0.75, 'count': 85, 'sector': 'S4'},
      {'x': size.width * 0.38, 'y': size.height * 0.80, 'count': 18, 'sector': 'S1'},
    ];

    for (final c in mockClusters) {
      final sector = c['sector'] as String;
      if (selectedSector != 'ALL' && selectedSector != sector) continue;

      final count = c['count'] as int;
      final x = c['x'] as double;
      final y = c['y'] as double;

      final clusterColor = DensityClusterEvaluator.getClusterColorValue(count);
      final radius = DensityClusterEvaluator.getClusterRadius(count);

      final haloAlpha = (0.20 + (pulseFraction * 0.15)).clamp(0.0, 1.0);
      final haloPaint = Paint()
        ..color = clusterColor.withValues(alpha: haloAlpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius * (1.2 + pulseFraction * 0.35), haloPaint);

      final clusterPaint = Paint()
        ..color = clusterColor.withValues(alpha: 0.90)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, clusterPaint);

      final textSpan = TextSpan(
        text: '$count',
        style: const TextStyle(color: AppColors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  void _drawLandmarkPins(Canvas canvas, Size size) {
    _drawPin(canvas, Offset(size.width * 0.20, size.height * 0.30), '🚩 Start: Zero Mile', AppColors.ink);
    _drawPin(canvas, Offset(size.width * 0.45, size.height * 0.25), '💧 Samvidhan Sq', AppColors.info);
    _drawPin(canvas, Offset(size.width * 0.75, size.height * 0.75), '🏁 Deekshabhoomi', AppColors.success);
  }

  void _drawPin(Canvas canvas, Offset offset, String label, Color dotColor) {
    final pinPaint = Paint()..color = dotColor..style = PaintingStyle.fill;
    canvas.drawCircle(offset, 4.0, pinPaint);

    final bgPaint = Paint()..color = AppColors.landmarkTextBg..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = AppColors.hairlineSoft..strokeWidth = 0.5..style = PaintingStyle.stroke;

    final span = TextSpan(
      text: label,
      style: const TextStyle(color: AppColors.ink, fontSize: 8.5, fontWeight: FontWeight.w700),
    );
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();

    final textRect = Rect.fromCenter(
      center: Offset(offset.dx, offset.dy - 11),
      width: tp.width + 8,
      height: tp.height + 4,
    );
    final rrect = RRect.fromRectAndRadius(textRect, const Radius.circular(AppRadius.sm));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);
    tp.paint(canvas, Offset(textRect.left + 4, textRect.top + 2));
  }

  @override
  bool shouldRepaint(covariant _NagpurVectorMapPainter oldDelegate) {
    return oldDelegate.pulseFraction != pulseFraction ||
        oldDelegate.zoomScale != zoomScale ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.selectedSector != selectedSector;
  }
}
