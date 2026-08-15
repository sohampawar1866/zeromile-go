// test/services/mapbox_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/services/mapbox_service.dart';
import 'package:flutter_core/utils/nagpur_poi_registry.dart';

void main() {
  group('NagpurPoiRegistry', () {
    test('search returns matching colleges and landmarks', () {
      final vnitResults = NagpurPoiRegistry.search('vnit');
      expect(vnitResults.isNotEmpty, isTrue);
      expect(vnitResults.first.name.contains('VNIT'), isTrue);

      final rcoemResults = NagpurPoiRegistry.search('rcoem');
      expect(rcoemResults.isNotEmpty, isTrue);
      expect(rcoemResults.first.name.contains('Ramdeobaba'), isTrue);

      final zeroMile = NagpurPoiRegistry.search('zero mile');
      expect(zeroMile.isNotEmpty, isTrue);
      expect(zeroMile.first.name.contains('Zero Mile'), isTrue);
    });

    test('findClosest locates closest landmark accurately', () {
      // Coordinates near Zero Mile (21.1458, 79.0882)
      final closest = NagpurPoiRegistry.findClosest(21.1459, 79.0883, maxDistanceKm: 0.5);
      expect(closest, isNotNull);
      expect(closest!.name.contains('Zero Mile'), isTrue);
    });
  });

  group('MapboxService Route & Interpolation', () {
    test('fetchCyclingRoute generates valid interpolated route offline', () async {
      final service = MapboxService();
      const start = MapPoint(latitude: 21.1458, longitude: 79.0882, name: 'Zero Mile');
      const finish = MapPoint(latitude: 21.1290, longitude: 79.0670, name: 'Deekshabhoomi');

      final result = await service.fetchCyclingRoute([start, finish]);
      expect(result.coordinates.isNotEmpty, isTrue);
      expect(result.distanceKm, greaterThan(0.0));
      expect(result.durationMinutes, greaterThan(0.0));
      expect(result.rawGeojson['type'], equals('Feature'));
    });

    test('searchNagpurLocation returns instant local POI results', () async {
      final service = MapboxService();
      final results = await service.searchNagpurLocation('medical');
      expect(results.isNotEmpty, isTrue);
      expect(results.any((r) => r.name.toLowerCase().contains('medical')), isTrue);
    });
  });
}
