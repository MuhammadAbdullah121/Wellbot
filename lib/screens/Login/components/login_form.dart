import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellbotapp/auth_service.dart';
import 'package:wellbotapp/components/already_have_an_account_acheck.dart';
import 'package:wellbotapp/components/forgot_password.dart';
import 'package:wellbotapp/constants.dart';
import 'package:wellbotapp/screens/HomeScreen/home_screen.dart';
import 'package:wellbotapp/screens/Signup/signup_screen.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('emailField'),
              controller: emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'email is required';
                }
                if (!value.contains('@')) {
                  return 'Email is not Valid';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                label: const Text("registered email"),
                hintText: "abc@xyz.com",
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.person),
                ),
                fillColor: Colors.lightBlue[50],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding),
              child: TextFormField(
                key: const Key('passwordField'),
                controller: passwordController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'password is required';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                obscureText: true,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  label: const Text("Password"),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(Icons.lock),
                  ),
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding * 0.1),
            ElevatedButton(
              key: const Key('loginButton'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  bool isSuccess = await login(
                    context: context,
                    email: emailController.text,
                    password: passwordController.text,
                  );
                  if (isSuccess) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  }
                }
              },
              child: const Text("LOGIN"),
            ),
            const SizedBox(height: defaultPadding * 0.5),
            AlreadyHaveAnAccountCheck(
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              },
            ),
            const SizedBox(height: defaultPadding * 0.5),
            ForgotPasswordButton(
              onPress: () {
                Navigator.pushNamed(context, '/reset-password');
              },
            ),
            const SizedBox(height: defaultPadding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Or login with:",
                  style: TextStyle(color: Colors.black.withOpacity(0.6)),
                ),
              ],
            ),
            const SizedBox(height: defaultPadding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SocialIcon(
                  iconSrc: "assets/icons/google-plus.svg",
                  press: () async {
                    await signInWithGoogle();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SocialIcon extends StatelessWidget {
  final String iconSrc;
  final VoidCallback press;

  const SocialIcon({
    super.key,
    required this.iconSrc,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('socialIcon'),
      onTap: press,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 2,
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
        child: SvgPicture.asset(
          iconSrc,
          height: 25,
          width: 25,
        ),
      ),
    );
  }
}
