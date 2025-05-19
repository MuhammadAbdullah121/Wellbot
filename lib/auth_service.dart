import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void _showSnackbar(BuildContext context, String message) {
  if (ScaffoldMessenger.maybeOf(context) != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<bool> login({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  try {
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Show success message
    _showSnackbar(context, "Welcome back, ${credential.user?.email ?? 'User'}!");
    return true; // Return true if login succeeds
  } on FirebaseAuthException catch (e) {
    String message;
    if (e.code == 'user-not-found') {
      message = 'No user found for that email.';
    } else if (e.code == 'wrong-password') {
      message = 'Wrong password provided for that user.';
    } else {
      message = "An authentication error occurred. Please try again.";
    }
    _showSnackbar(context, message);
    return false; // Return false on FirebaseAuthException
  } catch (e) {
    _showSnackbar(context, "An unexpected error occurred. Please try again.");
    return false; // Return false on any other error
  }
}

Future<bool> signup({
  required BuildContext context,
  required String email,
  required String password,
}) async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Show a welcome message
    _showSnackbar(context, "Welcome, ${credential.user?.email ?? 'User'}!");
    return true;
  } on FirebaseAuthException catch (e) {
    String message;
    switch (e.code) {
      case 'weak-password':
        message = "The password provided is too weak.";
        break;
      case 'email-already-in-use':
        message = "The account already exists for that email.";
        break;
      default:
        message = "An authentication error occurred. Please try again.";
    }
    _showSnackbar(context, message);
    return false; // Return false on FirebaseAuthException
  } catch (e) {
    _showSnackbar(context, "An unexpected error occurred. Please try again.");
    return false; // Return false on any other error
  }
}

Future<UserCredential> signInWithGoogle() async {
  // Trigger the authentication flow
  final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

  // Obtain the auth details from the request
  final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

  // Create a new credential
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth?.accessToken,
    idToken: googleAuth?.idToken,
  );

  // Once signed in, return the UserCredential
  return await FirebaseAuth.instance.signInWithCredential(credential);
}

Future<bool> sendResetPasswordLink({
  required BuildContext context,
  required String email,
}) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    _showSnackbar(context, "Password reset link sent successfully.");
    return true;
  } catch (e) {
    _showSnackbar(context, "An error occurred while sending the reset link.");
    return false;
  }
}
