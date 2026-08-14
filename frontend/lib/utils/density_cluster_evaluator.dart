// lib/utils/density_cluster_evaluator.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/user_live_location.dart';

class DensityCluster {
  final double centerLatitude;
  final double centerLongitude;
  final int pointCount;
  final String hexColor;
  final Color color;
  final double radius;
  final List<UserLiveLocation> locations;

  DensityCluster({
    required this.centerLatitude,
    required this.centerLongitude,
    required this.pointCount,
    required this.hexColor,
    required this.color,
    required this.radius,
    required this.locations,
  });

  DensityCluster copyWith({
    double? centerLatitude,
    double? centerLongitude,
    int? pointCount,
    String? hexColor,
    Color? color,
    double? radius,
    List<UserLiveLocation>? locations,
  }) {
    return DensityCluster(
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      pointCount: pointCount ?? this.pointCount,
      hexColor: hexColor ?? this.hexColor,
      color: color ?? this.color,
      radius: radius ?? this.radius,
      locations: locations ?? this.locations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'point_count': pointCount,
      'hex_color': hexColor,
      'radius': radius,
      'locations_count': locations.length,
    };
  }
}

class DensityClusterEvaluator {
  /// Dynamic Step Color Expressions matching Section 6.3 of PROJECT_PLAN.md:
  /// - 1 - 24 participants: Soft Cyan (#51BBD6)
  /// - 25 - 99 participants: Sky Blue (#3BB2D0)
  /// - 100 - 299 participants: Amber / Yellow (#F1F075)
  /// - 300 - 599 participants: Coral Red (#E55E5E)
  /// - 600+ participants: Deep Intense Purple (#7B1FA2)
  static String getClusterColor(int count) {
    if (count >= 600) return '#7B1FA2';
    if (count >= 300) return '#E55E5E';
    if (count >= 100) return '#F1F075';
    if (count >= 25) return '#3BB2D0';
    return '#51BBD6';
  }

  static Color getClusterColorValue(int count) {
    if (count >= 600) return AppColors.clusterDeepPurple;
    if (count >= 300) return AppColors.clusterCoralRed;
    if (count >= 100) return AppColors.clusterAmber;
    if (count >= 25) return AppColors.clusterSkyBlue;
    return AppColors.clusterCyan;
  }

  static double getClusterRadius(int count) {
    if (count >= 600) return 44.0;
    if (count >= 300) return 34.0;
    if (count >= 100) return 26.0;
    if (count >= 25) return 20.0;
    return 14.0;
  }

  /// High-performance spatial grid bucket clustering algorithm: O(N) linear time complexity
  static List<DensityCluster> computeClusters(
    List<UserLiveLocation> pings, {
    double clusterRadiusKm = 0.35,
  }) {
    if (pings.isEmpty) return [];

    // Approximate 1 deg latitude ~= 111.0 km, longitude scaled by cos(lat)
    final double gridLatSize = clusterRadiusKm / 111.0;
    final double gridLonSize = clusterRadiusKm / (111.0 * cos(pings.first.latitude * pi / 180.0));

    final Map<String, List<UserLiveLocation>> grid = {};

    for (final ping in pings) {
      final int latBucket = (ping.latitude / gridLatSize).floor();
      final int lonBucket = (ping.longitude / gridLonSize).floor();
      final key = '$latBucket:$lonBucket';

      grid.putIfAbsent(key, () => []).add(ping);
    }

    final clusters = <DensityCluster>[];

    grid.forEach((key, bucketPings) {
      double sumLat = 0.0;
      double sumLng = 0.0;
      for (final p in bucketPings) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }

      final count = bucketPings.length;
      clusters.add(
        DensityCluster(
          centerLatitude: sumLat / count,
          centerLongitude: sumLng / count,
          pointCount: count,
          hexColor: getClusterColor(count),
          color: getClusterColorValue(count),
          radius: getClusterRadius(count),
          locations: bucketPings,
        ),
      );
    });

    return clusters;
  }
}
