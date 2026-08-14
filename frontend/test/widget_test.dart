// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_core/ui/core/widgets/status_badge.dart';
import 'package:flutter_core/ui/core/widgets/route_checkpoint_stepper.dart';
import 'package:flutter_core/ui/core/widgets/broadcast_card.dart';
import 'package:flutter_core/ui/core/widgets/sos_triage_card.dart';

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

    testWidgets('RouteCheckpointStepper renders milestones with icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RouteCheckpointStepper(
              checkpoints: [],
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

      expect(find.text('🚨 MEDICAL DISTRESS'), findsOneWidget);
      expect(find.text('Rahul Deshmukh (+91 98220 99999)'), findsOneWidget);
      expect(find.text('Resolve Locally'), findsOneWidget);

      await tester.tap(find.text('Resolve Locally'));
      expect(resolved, isTrue);
    });
  });
}
