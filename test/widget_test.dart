import 'package:flutter_test/flutter_test.dart';

import 'package:city_care/main.dart';

void main() {
  testWidgets('CityCare app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CityCareApp());

    // Verify that our app loads
    expect(find.text('CityCare - Accueil'), findsOneWidget);
  });
}
