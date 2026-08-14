import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_core/main.dart';

void main() {
  testWidgets('ZeroMile Go smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ZeroMileGoApp());
    expect(find.text('ZeroMile Go'), findsWidgets);
  });
}
