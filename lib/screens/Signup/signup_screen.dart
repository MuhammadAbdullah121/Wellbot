import 'package:flutter/material.dart';
import 'package:wellbotapp/constants.dart';
import 'package:wellbotapp/responsive.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/screens/Signup/components/sign_up_top_image.dart';
import 'package:wellbotapp/screens/Signup/components/signup_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Background(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileSignupScreen(),
          
          desktop: Row(
            children: [
              Expanded(
                child: SignUpScreenTopImage(),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 450,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SignUpForm(),
                        SizedBox(height: defaultPadding / 2),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MobileSignupScreen extends StatelessWidget {
  const MobileSignupScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          SignUpScreenTopImage(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: defaultPadding),
            child: SignUpForm(),
          ),
          SizedBox(height: defaultPadding),
        ],
      ),
    );
  }
}
