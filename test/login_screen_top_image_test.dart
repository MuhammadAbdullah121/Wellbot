import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/Login/components/login_screen_top_image.dart';

void main() {
  testWidgets('Renders LOGIN title and SVG image', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LoginScreenTopImage()),
      ),
    );

    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}