// lib/ui/core/widgets/fluid_tap_scale.dart

import 'package:flutter/material.dart';

/// Kinetic Athletic Tap Scale Micro-Interaction Widget
/// Mimics Nike's signature tap collapse feedback (scale(0.96) with instant curve).
class FluidTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const FluidTapScale({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<FluidTapScale> createState() => _FluidTapScaleState();
}

class _FluidTapScaleState extends State<FluidTapScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 75),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.955).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
