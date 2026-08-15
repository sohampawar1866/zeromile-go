// test/widgets/presence_tracker_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_core/ui/features/home/components/presence_tracker_card.dart';

void main() {
  group('PresenceTrackerCard Widget Tests', () {
    testWidgets('renders Not Checked In state and fires onCheckIn callback', (tester) async {
      bool checkedInTapped = false;
      bool completedTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PresenceTrackerCard(
              membership: null,
              isLiveWindow: true,
              onCheckIn: () => checkedInTapped = true,
              onComplete: () => completedTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Event Participation Status'), findsOneWidget);
      expect(find.text('NOT CHECKED IN'), findsOneWidget);
      expect(find.text('Check-In at Muster'), findsOneWidget);

      await tester.tap(find.text('Check-In at Muster'));
      await tester.pumpAndSettle();

      expect(checkedInTapped, isTrue);
      expect(completedTapped, isFalse);
    });

    testWidgets('renders Checked In state accurately with timestamp', (tester) async {
      final membership = GroupMembership(
        id: 'm-1',
        domainId: 'domain-1',
        groupId: 'group-1',
        userId: 'user-1',
        isActive: true,
        isLeader: false,
        participationStatus: ParticipationStatus.checkedIn,
        checkinTime: DateTime(2026, 8, 15, 6, 30),
        joinedAt: DateTime(2026, 8, 1),
        groupName: 'VNIT Riders',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PresenceTrackerCard(
              membership: membership,
              isLiveWindow: true,
              onCheckIn: () {},
              onComplete: () {},
            ),
          ),
        ),
      );

      expect(find.text('CHECKED IN'), findsOneWidget);
      expect(find.text('Checked In'), findsOneWidget);
      expect(find.textContaining('6:30'), findsOneWidget);
    });
  });
}
