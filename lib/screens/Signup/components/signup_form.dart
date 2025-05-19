import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wellbotapp/auth_service.dart';
import 'package:wellbotapp/components/already_have_an_account_acheck.dart';
import 'package:wellbotapp/constants.dart';
import 'package:wellbotapp/screens/HomeScreen/home_screen.dart';
import 'package:wellbotapp/screens/Login/login_screen.dart';
import 'package:wellbotapp/screens/personal_information_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  SignUpFormState createState() => SignUpFormState();
}

class SignUpFormState extends State<SignUpForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
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
            onSaved: (email) {},
            decoration: InputDecoration(
              label: const Text("Email"),
              hintText: "abc@xyz.com",
              hintStyle: const TextStyle(
                fontSize: 14,
              ),
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
            padding: const EdgeInsets.only(top: 16.0),
            child: TextFormField(
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
                label: const Text('Password'),
                hintStyle: const TextStyle(
                  fontSize: 14,
                ),
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
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextFormField(
              controller: confirmPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'password is required';
                }
                if (passwordController.text.toString() != value) {
                  return 'Password not Matched';
                }
                return null;
              },
              textInputAction: TextInputAction.done,
              obscureText: true,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                label: const Text('Confirm Password'),
                hintStyle: const TextStyle(
                  fontSize: 14,
                ),
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
          const SizedBox(height: defaultPadding),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                bool isSuccess = await signup(
                    context: context,
                    email: emailController.text,
                    password: passwordController.text);

                if (isSuccess) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInformationForm(email: emailController.text),
                    ),
                  );
                }
              }
            },
            child: const Text("SIGN UP"),
          ),
          const SizedBox(height: defaultPadding * 0.5),
          AlreadyHaveAnAccountCheck(
            login: false,
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const LoginScreen();
                  },
                ),
              );
            },
          ),
          const SizedBox(height: defaultPadding * 0.5),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              "Or signup with:",
              style: TextStyle(color: Colors.black.withOpacity(0.6)),
            ),
          ]),
          const SizedBox(height: defaultPadding * 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialIcon(
                iconSrc: "assets/icons/google-plus.svg",
                press: () async {
                  final credential = await signInWithGoogle();
                  {
                    print('$credential');
                    // Assuming null means sign-in failed
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(),
                      ),
                    );
                  }
                },
              ),
              // SocialIcon(
              //   iconSrc: "assets/icons/facebook.svg",
              //   press: ()  {
              // },),
              // SocialIcon(
              //   iconSrc: "assets/icons/twitter.svg",
              //   press: () {},
              // ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
