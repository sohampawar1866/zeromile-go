// test/widgets/emergency_sos_modal_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_core/ui/core/dialogs/emergency_sos_modal.dart';

void main() {
  group('EmergencySosModal Widget Tests', () {
    testWidgets('renders all emergency categories and triggers callback on submit', (tester) async {
      EmergencyType? triggeredType;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  EmergencySosModal.show(
                    context,
                    onTrigger: (type) {
                      triggeredType = type;
                    },
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open Modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY SOS DISTRESS'), findsOneWidget);
      expect(find.text('Medical Assistance / Injury / Heat Stroke'), findsOneWidget);
      expect(find.text('Vehicle / Bicycle Breakdown'), findsOneWidget);
      expect(find.text('Safety / Physical Threat / Harassment'), findsOneWidget);

      // Select Breakdown category
      await tester.tap(find.text('Vehicle / Bicycle Breakdown'));
      await tester.pumpAndSettle();

      // Submit SOS
      await tester.tap(find.text('BROADCAST DISTRESS NOW'));
      await tester.pumpAndSettle();

      expect(triggeredType, equals(EmergencyType.breakdown));
    });
  });
}
