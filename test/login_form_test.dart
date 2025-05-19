import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/Login/components/login_form.dart';

void main() {
  testWidgets('LoginForm builds and contains form fields and button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView( // Allow scrolling for overflow safety
              child: SizedBox(
                width: 600, // Wider width to prevent Row overflow
                child: LoginForm(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Wait for all widgets to build

    expect(find.byKey(const Key('emailField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
    expect(find.byKey(const Key('socialIcon')), findsOneWidget);
  });
}
