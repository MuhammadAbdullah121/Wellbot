import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/Signup/components/signup_form.dart';
import 'package:wellbotapp/screens/Signup/signup_screen.dart';

void main() {
  testWidgets('MobileSignupScreen builds and contains SignUpForm', (WidgetTester tester) async {
    // Wrap MobileSignupScreen with MaterialApp to provide Material context
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileSignupScreen(),
        ),
      ),
    );

    // Allow any animations/layout builds to complete
    await tester.pumpAndSettle();

    // Verify SignUpForm exists
    expect(find.byType(SignUpForm), findsOneWidget);
  });
}
