// test/utils/density_cluster_evaluator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('DensityClusterEvaluator Tests', () {
    test('getClusterColor returns correct step color thresholds', () {
      expect(DensityClusterEvaluator.getClusterColor(10), equals('#51BBD6')); // Soft Cyan
      expect(DensityClusterEvaluator.getClusterColor(50), equals('#3BB2D0')); // Sky Blue
      expect(DensityClusterEvaluator.getClusterColor(150), equals('#F1F075')); // Amber / Yellow
      expect(DensityClusterEvaluator.getClusterColor(450), equals('#E55E5E')); // Coral Red
      expect(DensityClusterEvaluator.getClusterColor(700), equals('#7B1FA2')); // Deep Purple
    });

    test('getClusterRadius scales appropriately with participant density', () {
      expect(DensityClusterEvaluator.getClusterRadius(10), equals(14.0));
      expect(DensityClusterEvaluator.getClusterRadius(50), equals(20.0));
      expect(DensityClusterEvaluator.getClusterRadius(150), equals(26.0));
      expect(DensityClusterEvaluator.getClusterRadius(400), equals(34.0));
      expect(DensityClusterEvaluator.getClusterRadius(800), equals(44.0));
    });

    test('computeClusters groups nearby coordinates into spatial buckets', () {
      final pings = [
        UserLiveLocation(
          id: 'ping-1',
          domainId: 'cycling-2026',
          userId: 'user-1',
          latitude: 21.1465,
          longitude: 79.0882,
          updatedAt: DateTime.now(),
        ),
        UserLiveLocation(
          id: 'ping-2',
          domainId: 'cycling-2026',
          userId: 'user-2',
          latitude: 21.1466,
          longitude: 79.0883,
          updatedAt: DateTime.now(),
        ),
        UserLiveLocation(
          id: 'ping-3',
          domainId: 'cycling-2026',
          userId: 'user-3',
          latitude: 21.2000,
          longitude: 79.1500,
          updatedAt: DateTime.now(),
        ),
      ];

      final clusters = DensityClusterEvaluator.computeClusters(pings, clusterRadiusKm: 0.5);
      expect(clusters.length, equals(2)); // Pings 1 and 2 clustered together, Ping 3 in separate cluster

      final denseCluster = clusters.firstWhere((c) => c.pointCount == 2);
      expect(denseCluster.pointCount, equals(2));
      expect(denseCluster.locations.length, equals(2));
    });

    test('computeClusters handles empty lists gracefully', () {
      final clusters = DensityClusterEvaluator.computeClusters([]);
      expect(clusters, isEmpty);
    });
  });
}
