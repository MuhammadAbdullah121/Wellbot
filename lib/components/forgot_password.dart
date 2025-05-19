import 'package:flutter/material.dart';
import 'package:wellbotapp/auth_service.dart';
import 'package:wellbotapp/constants.dart';

class ForgotPasswordButton extends StatelessWidget {
  final Function? onPress;
  const ForgotPasswordButton({
    Key? key,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: onPress as void Function()?,
          child: const Text(
            "Forgot Password?",
            style: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        backgroundColor: kPrimaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(defaultPadding),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Email is not valid';
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  label: const Text("Registered email"),
                  hintText: "abc@xyz.com",
                  hintStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(Icons.email),
                  ),
                  fillColor: Colors.lightBlue[50],
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: defaultPadding * 0.5),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    bool isSuccess = await sendResetPasswordLink(
                      context: context, 
                      email: emailController.text
                    );
                    if (isSuccess) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: const Text("Send email"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
