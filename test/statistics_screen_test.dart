import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wellbotapp/firebase_options.dart';
import 'package:wellbotapp/screens/statistics_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('StatisticsScreen loads and displays charts/empty states',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp( // ✅ FIXED: Removed const
        home: StatisticsScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Health Tracking'), findsOneWidget);
    expect(find.text('Financial Overview'), findsOneWidget);
    expect(find.text('Goal Progress'), findsOneWidget);
    expect(find.text('Time Management'), findsOneWidget);
    expect(find.text('Social Activities'), findsOneWidget);

    expect(find.textContaining('No'), findsWidgets);
  });
}
