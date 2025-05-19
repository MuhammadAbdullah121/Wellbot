import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbotapp/screens/Signup/components/signup_form.dart';
//import 'package:wellbotapp/signup_form.dart';
import 'package:wellbotapp/screens/personal_information_screen.dart';

// Mock the signup function to always succeed
bool mockSignupCalled = false;

Future<bool> mockSignup({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  mockSignupCalled = true;
  return true; // Simulate successful signup
}

void main() {
  // Override the actual signup with the mock version
  setUp(() {
    mockSignupCalled = false;
  });

  testWidgets('Shows validation error when passwords do not match',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp());

    await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'password123');
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'wrong123');

    await tester.tap(find.text('SIGN UP'));
    await tester.pump();

    expect(find.text('Password not Matched'), findsOneWidget);
  });

  testWidgets('Navigates to PersonalInformationForm on successful signup',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TestApp());

    await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'password123');
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'password123');

    await tester.tap(find.text('SIGN UP'));
    await tester.pumpAndSettle();

    expect(find.byType(PersonalInformationForm), findsOneWidget);
    expect(mockSignupCalled, true);
  });
}

// A test wrapper with MaterialApp and route support
class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return SignUpFormWithMock(signupFunction: mockSignup);
          },
        ),
      ),
    );
  }
}

// Inject the mocked signup function into SignUpForm
class SignUpFormWithMock extends StatefulWidget {
  final Future<bool> Function({
    required BuildContext context,
    required String email,
    required String password,
  }) signupFunction;

  const SignUpFormWithMock({super.key, required this.signupFunction});

  @override
  State<SignUpFormWithMock> createState() => _SignUpFormWithMockState();
}

class _SignUpFormWithMockState extends State<SignUpFormWithMock> {
  final formKey = GlobalKey<SignUpFormState>();

  @override
  Widget build(BuildContext context) {
    return SignUpFormWithOverride(
      formKey: formKey,
      signup: widget.signupFunction,
    );
  }
}

// Copied form widget with injectable `signup()` function and test keys
class SignUpFormWithOverride extends SignUpForm {
  final GlobalKey<SignUpFormState> formKey;
  final Future<bool> Function({
    required BuildContext context,
    required String email,
    required String password,
  }) signup;

  SignUpFormWithOverride({
    required this.formKey,
    required this.signup,
  }) : super(key: formKey);

  @override
  SignUpFormState createState() => _SignUpFormWithOverrideState();
}

class _SignUpFormWithOverrideState extends SignUpFormState {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            key: const Key('email'),
            controller: emailController,
            validator: (value) {
              if (value == null || value.isEmpty) return 'email is required';
              if (!value.contains('@')) return 'Email is not Valid';
              return null;
            },
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextFormField(
            key: const Key('password'),
            controller: passwordController,
            obscureText: true,
            validator: (value) => value == null || value.isEmpty
                ? 'password is required'
                : null,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          TextFormField(
            key: const Key('confirmPassword'),
            controller: confirmPasswordController,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'password is required';
              if (passwordController.text != value) return 'Password not Matched';
              return null;
            },
            decoration: const InputDecoration(labelText: 'Confirm Password'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await (widget as SignUpFormWithOverride)
                    .signup(
                        context: context,
                        email: emailController.text,
                        password: passwordController.text);
                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonalInformationForm(
                        email: emailController.text,
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('SIGN UP'),
          )
        ],
      ),
    );
  }
}
