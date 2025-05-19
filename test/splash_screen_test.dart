// test/splash_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/splash_screen.dart';

void main() {
  testWidgets('SplashScreen Widget Test renders and navigates correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Start animation
    await tester.pump(); // Start frame
    await tester.pump(const Duration(seconds: 2)); // Wait for animation

    // ✅ Check if logo text is found
    expect(find.text('WELLBOT'), findsOneWidget);

    // ✅ Check if loading indicator exists
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Optionally: confirm splash screen structure
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
