import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/Login/login_screen.dart';
import 'package:wellbotapp/screens/Login/components/login_form.dart';
import 'package:wellbotapp/screens/Login/components/login_screen_top_image.dart';
import 'package:wellbotapp/responsive.dart';

void main() {
  testWidgets('LoginScreen builds and contains expected widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(LoginForm), findsOneWidget);
    expect(find.byType(LoginScreenTopImage), findsOneWidget);
    expect(find.byType(Responsive), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets); // updated line
  });
}
