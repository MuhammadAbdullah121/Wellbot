import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbotapp/screens/Welcome/welcome_screen.dart';
import 'package:wellbotapp/screens/gettingstarted_screen.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _hasSeenGettingStarted = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeLaunch();
  }

  Future<void> _checkFirstTimeLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('hasSeenGettingStarted') ?? false;
    setState(() {
      _hasSeenGettingStarted = hasSeen;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return _hasSeenGettingStarted
          ? const WelcomeScreen()
          : GettingStartedScreen(
              onGetStarted: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hasSeenGettingStarted', true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
            );
    }
  }
}
