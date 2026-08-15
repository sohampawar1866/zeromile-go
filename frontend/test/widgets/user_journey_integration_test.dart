// test/widgets/user_journey_integration_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_core/ui/features/home/participant_home_screen.dart';
import 'package:flutter_core/ui/core/widgets/density_cluster_map_view.dart';
import 'package:flutter_core/ui/core/dialogs/emergency_sos_modal.dart';
import 'package:flutter_core/ui/features/admin_console/tabs/mapbox_route_studio_card.dart';

void main() {
  group('End-to-End User Journey Integration Tests', () {
    testWidgets('Journey 1: Participant Home Screen renders and completes muster check-in', (tester) async {
      final homeVm = ParticipantHomeViewModel();
      addTearDown(homeVm.dispose);

      final domain = EventDomain(
        id: 'domain-nagpur-2026',
        name: 'Vikasit Nagpur 2026 Mega Cycling Rally',
        slug: 'cycling-2026',
        type: EventDomainType.cycling,
        status: EventDomainStatus.liveActive,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ParticipantHomeScreen(
            activeDomain: domain,
            checkpoints: const [],
            viewModel: homeVm,
            currentUserId: 'user-soham-1',
            onNavigateToGroups: () {},
          ),
        ),
      );

      // Verify header schedule banner
      expect(find.text('Event Participation'), findsOneWidget);
      expect(find.text('Not Checked In'), findsOneWidget);
      expect(find.text('Check In at Muster'), findsOneWidget);

      // Tap Check-in
      await tester.tap(find.text('Check In at Muster'));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Emergency SOS FAB is visible during live window
      expect(find.text('SOS DISTRESS'), findsOneWidget);
    });

    testWidgets('Journey 2: Mapbox 3D Route Studio interaction and time-of-day mode switcher', (tester) async {
      final domain = EventDomain(
        id: 'domain-1',
        name: 'Nagpur Rally',
        slug: 'rally',
        type: EventDomainType.cycling,
        status: EventDomainStatus.liveActive,
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MapboxRouteStudioCard(
                activeDomain: domain,
                existingCheckpoints: [
                  RouteCheckpoint(
                    id: 'cp-1',
                    domainId: 'domain-1',
                    name: 'Zero Mile Freedom Park',
                    latitude: 21.1458,
                    longitude: 79.0882,
                    sequenceOrder: 1,
                    checkpointType: CheckpointType.start,
                    createdAt: DateTime.now(),
                  ),
                  RouteCheckpoint(
                    id: 'cp-2',
                    domainId: 'domain-1',
                    name: 'Deekshabhoomi Stupa',
                    latitude: 21.1290,
                    longitude: 79.0670,
                    sequenceOrder: 2,
                    checkpointType: CheckpointType.finish,
                    createdAt: DateTime.now(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(DensityClusterMapView), findsOneWidget);
      expect(find.text('TOTAL OFFICIAL MAPBOX 3D CYCLING DISTANCE'), findsOneWidget);
      expect(find.text('🚴 Multi-Rider 3D Live GPS Tracking'), findsOneWidget);
      expect(find.text('👑 Rajesh Sharma (Leader)'), findsOneWidget);

      // Verify Time-of-day lighting buttons
      expect(find.text('🌅'), findsOneWidget);
      expect(find.text('☀️'), findsOneWidget);
      expect(find.text('🌇'), findsOneWidget);
      expect(find.text('🌙'), findsOneWidget);

      // Switch to Cyberpunk Night Mode
      await tester.tap(find.text('🌙'));
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll and Tap Save Draft
      await tester.ensureVisible(find.text('💾 Save Draft'));
      await tester.tap(find.text('💾 Save Draft'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Journey 3: Emergency SOS Modal trigger workflow', (tester) async {
      EmergencyType? dispatchedType;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  EmergencySosModal.show(
                    context,
                    onTrigger: (type) {
                      dispatchedType = type;
                    },
                  );
                },
                child: const Text('TRIGGER SOS'),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('TRIGGER SOS'));
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY SOS DISTRESS'), findsOneWidget);
      expect(find.text('Safety / Physical Threat / Harassment'), findsOneWidget);

      // Tap Security/Threat option
      await tester.tap(find.text('Safety / Physical Threat / Harassment'));
      await tester.pumpAndSettle();

      // Dispatch
      await tester.tap(find.text('BROADCAST DISTRESS NOW'));
      await tester.pumpAndSettle();

      expect(dispatchedType, equals(EmergencyType.threat));
    });
  });
}
