import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/profile_page.dart';

void main() {
  testWidgets('ProfilePage builds and shows email', (WidgetTester tester) async {
    // Build the ProfilePage widget with a test email
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(email: 'test@example.com'),
      ),
    );

    // Verify the ProfilePage is built and email text is displayed
    expect(find.text('test@example.com'), findsOneWidget);

    // Verify the "Edit" button is present
    expect(find.text('Edit'), findsOneWidget);
  });
}
