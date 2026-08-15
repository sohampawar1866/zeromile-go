// lib/ui/core/widgets/map_view_platform/map_view_platform_web.dart

// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../../../../models/route_checkpoint.dart';

bool _isRegistered = false;
const String _viewType = 'mapbox-3d-web-view';

void initPlatformMapbox() {
  if (!_isRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src = 'mapbox_3d.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.backgroundColor = '#0b0f19';
        return iframe;
      },
    );
    _isRegistered = true;
  }
}

Widget buildMapboxView({
  required void Function(dynamic map) onMapCreated,
  required void Function(dynamic event) onStyleLoaded,
}) {
  initPlatformMapbox();
  return const HtmlElementView(
    key: ValueKey('live-map-web'),
    viewType: _viewType,
  );
}

Future<void> updatePlatformRouteLayer(
  dynamic mapInstance,
  List<RouteCheckpoint> checkpoints,
) async {
  // Web iframe handles route natively via Mapbox GL JS
}
