import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellbotapp/screens/Signup/components/sign_up_top_image.dart';

void main() {
  testWidgets('SignUpTopImage renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
          home: Scaffold(body: SignUpScreenTopImage()))
    );

    expect(find.text('SIGN UP'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}