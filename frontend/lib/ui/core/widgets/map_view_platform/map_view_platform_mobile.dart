// lib/ui/core/widgets/map_view_platform/map_view_platform_mobile.dart

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../../models/route_checkpoint.dart';

const _kMapboxToken =
    'pk.eyJ1IjoicmFrc2hpdGxhZGRhIiwiYSI6ImNtc3RrN2cweTBsbDEyeHIwZnA5aXY5dHkifQ.0J-JnWi4wBW3T-8Nbtmgjg';

const _kNagpurLng = 79.0882;
const _kNagpurLat = 21.1458;

void initPlatformMapbox() {
  MapboxOptions.setAccessToken(_kMapboxToken);
}

Widget buildMapboxView({
  required void Function(dynamic map) onMapCreated,
  required void Function(dynamic event) onStyleLoaded,
}) {
  return MapWidget(
    key: const ValueKey('live-map-mobile'),
    onMapCreated: (map) {
      try {
        map.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(_kNagpurLng, _kNagpurLat)),
            zoom: 14.8,
            pitch: 55,
            bearing: 15,
          ),
        );
        map.style.setStyleURI(MapboxStyles.STANDARD);
      } catch (_) {}
      onMapCreated(map);
    },
    onStyleLoadedListener: (event) {
      onStyleLoaded(event);
    },
  );
}

Future<void> updatePlatformRouteLayer(
  dynamic mapInstance,
  List<RouteCheckpoint> checkpoints,
) async {
  if (mapInstance is! MapboxMap || checkpoints.length < 2) return;
  final map = mapInstance;

  final coords = checkpoints
      .map((cp) => Position(cp.longitude, cp.latitude))
      .toList();

  final geojson = '''{
    "type": "Feature",
    "properties": {},
    "geometry": {
      "type": "LineString",
      "coordinates": ${coords.map((p) => '[${p.lng},${p.lat}]').toList()}
    }
  }''';

  try {
    await map.style.addSource(
      GeoJsonSource(id: 'route-source', data: geojson),
    );

    // Layer 1 — outer radium green glow
    await map.style.addLayer(LineLayer(
      id: 'route-glow',
      sourceId: 'route-source',
      lineColor: 0xE600FF66,
      lineWidth: 22.0,
      lineBlur: 7.0,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
    ));

    // Layer 2 — cyan mid glow
    await map.style.addLayer(LineLayer(
      id: 'route-mid',
      sourceId: 'route-source',
      lineColor: 0xFF00F2FE,
      lineWidth: 10.0,
      lineBlur: 2.0,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
    ));

    // Layer 3 — solid white core
    await map.style.addLayer(LineLayer(
      id: 'route-core',
      sourceId: 'route-source',
      lineColor: 0xFFFFFFFF,
      lineWidth: 3.5,
      lineCap: LineCap.ROUND,
      lineJoin: LineJoin.ROUND,
    ));
  } catch (_) {}
}
