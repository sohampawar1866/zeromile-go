// test/widgets/shad_button_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/flutter_core.dart';

void main() {
  group('ShadButton Component Tests', () {
    testWidgets('renders primary button and responds to tap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ShadButton(
              text: 'Save Changes',
              icon: Icons.check,
              onPressed: () => tapped = true,
              variant: ShadButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders loading spinner and ignores tap when isLoading is true', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ShadButton(
              text: 'Submitting',
              isLoading: true,
              onPressed: () => tapped = true,
              variant: ShadButtonVariant.destructive,
            ),
          ),
        ),
      );

      expect(find.text('Submitting'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.text('Submitting'));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
    });
  });
}
