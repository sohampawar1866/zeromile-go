// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_core/ui/core/widgets/status_badge.dart';
import 'package:flutter_core/ui/core/widgets/route_checkpoint_stepper.dart';
import 'package:flutter_core/ui/core/widgets/broadcast_card.dart';
import 'package:flutter_core/ui/core/widgets/sos_triage_card.dart';
import 'package:flutter_core/ui/core/widgets/density_cluster_map_view.dart';

void main() {
  group('UI Design System & Core Widgets Tests', () {
    testWidgets('StatusBadge renders appropriate colors and text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(
              label: 'LIVE ACTIVE',
              type: StatusBadgeType.success,
              icon: Icons.check_circle,
            ),
          ),
        ),
      );

      expect(find.text('LIVE ACTIVE'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('DensityClusterMapView renders Mapbox 3D vector header and legend', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DensityClusterMapView(
              title: 'Nagpur Domain Loop',
              isInteractiveRouteBuilder: true,
            ),
          ),
        ),
      );

      expect(find.text('Nagpur Domain Loop'), findsOneWidget);
      expect(find.text('1-24'), findsOneWidget);
      expect(find.text('300+'), findsOneWidget);
    });

    testWidgets('RouteCheckpointStepper renders milestones with icons', (WidgetTester tester) async {
      final sampleCheckpoints = [
        RouteCheckpoint(
          id: 'cp-1',
          domainId: 'domain-1',
          name: 'Zero Mile Monument (Start Flag-off)',
          sequenceOrder: 1,
          checkpointType: CheckpointType.start,
          latitude: 21.1458,
          longitude: 79.0882,
          createdAt: DateTime.now(),
        ),
        RouteCheckpoint(
          id: 'cp-2',
          domainId: 'domain-1',
          name: 'Samvidhan Square (Water Point #1)',
          sequenceOrder: 2,
          checkpointType: CheckpointType.waterStation,
          latitude: 21.1500,
          longitude: 79.0800,
          createdAt: DateTime.now(),
        ),
        RouteCheckpoint(
          id: 'cp-3',
          domainId: 'domain-1',
          name: 'Deekshabhoomi Ground (Rally Finish & Pass)',
          sequenceOrder: 3,
          checkpointType: CheckpointType.finish,
          latitude: 21.1275,
          longitude: 79.0667,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteCheckpointStepper(
              checkpoints: sampleCheckpoints,
              completedIndex: 1,
            ),
          ),
        ),
      );

      expect(find.text('Zero Mile Monument (Start Flag-off)'), findsOneWidget);
      expect(find.text('Samvidhan Square (Water Point #1)'), findsOneWidget);
      expect(find.text('Deekshabhoomi Ground (Rally Finish & Pass)'), findsOneWidget);
    });

    testWidgets('BroadcastCard renders command alert styling', (WidgetTester tester) async {
      final msg = BroadcastMessage(
        id: 'msg-1',
        domainId: 'domain-1',
        senderId: 'user-1',
        senderRole: SenderRole.superAdmin,
        targetType: BroadcastTargetType.general,
        messageText: 'Extreme heat caution at Shankar Nagar',
        createdAt: DateTime(2026, 8, 14, 6, 30),
        senderName: 'Command Control',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BroadcastCard(message: msg),
          ),
        ),
      );

      expect(find.text('COMMAND ALERT'), findsOneWidget);
      expect(find.text('Extreme heat caution at Shankar Nagar'), findsOneWidget);
      expect(find.text('Origin: Command Control'), findsOneWidget);
    });

    testWidgets('SosTriageCard renders triage details and action buttons', (WidgetTester tester) async {
      final sos = SosEvent(
        id: 'sos-1',
        domainId: 'domain-1',
        senderUserId: 'user-1',
        senderName: 'Rahul Deshmukh',
        senderPhone: '+91 98220 99999',
        emergencyType: EmergencyType.medical,
        status: SosStatus.triggered,
        latitude: 21.1458,
        longitude: 79.0882,
        createdAt: DateTime(2026, 8, 14, 7, 15),
      );

      bool resolved = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SosTriageCard(
              event: sos,
              isSuperAdmin: false,
              onResolve: () => resolved = true,
            ),
          ),
        ),
      );

      expect(find.text('MEDICAL DISTRESS'), findsOneWidget);
      expect(find.text('Rahul Deshmukh (+91 98220 99999)'), findsOneWidget);
      expect(find.text('Resolve Locally'), findsOneWidget);

      await tester.tap(find.text('Resolve Locally'));
      expect(resolved, isTrue);
    });

    testWidgets('RouteTrackingBottomSheet renders milestone stepper and ETA', (WidgetTester tester) async {
      final sampleCheckpoints = [
        RouteCheckpoint(
          id: 'cp-1',
          domainId: 'domain-1',
          name: 'Zero Mile',
          sequenceOrder: 1,
          checkpointType: CheckpointType.start,
          latitude: 21.1458,
          longitude: 79.0882,
          createdAt: DateTime.now(),
        ),
        RouteCheckpoint(
          id: 'cp-2',
          domainId: 'domain-1',
          name: 'Water Point 1',
          sequenceOrder: 2,
          checkpointType: CheckpointType.waterStation,
          latitude: 21.1500,
          longitude: 79.0800,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouteTrackingBottomSheet(
              checkpoints: sampleCheckpoints,
              activeCheckpointIndex: 1,
              distanceRemainingKm: 3.5,
              estimatedArrivalTime: '8:15 AM',
              nextCheckpointName: 'Water Point 1',
            ),
          ),
        ),
      );

      expect(find.text('Heading to Water Point 1'), findsOneWidget);
      expect(find.text('8:15 AM'), findsOneWidget);
      expect(find.text('Zero Mile'), findsOneWidget);
      expect(find.text('Water Point 1'), findsOneWidget);
    });
  });
}
