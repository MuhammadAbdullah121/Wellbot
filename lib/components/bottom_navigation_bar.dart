import 'package:flutter/material.dart';
import 'package:wellbotapp/screens/HomeScreen/home_screen.dart';
import 'package:wellbotapp/screens/statistics_page.dart';
import 'package:wellbotapp/screens/profile_page.dart';
import 'package:wellbotapp/screens/ongoing_activities_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  Future<String> _getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');
    print('Retrieved email: $email'); // Debug print
    return email ?? '';
  }

  void _navigateToPage(int index) async {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => StatisticsScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OngoingActivitiesPage()),
        );
        break;
      case 3:
        final userEmail = await _getUserEmail();
        print('Navigating to profile with email: $userEmail'); // Debug print
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(email: userEmail),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        widget.onTap(index);
        _navigateToPage(index);
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.blue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: false,
      items: [
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              widget.onTap(0);
              _navigateToPage(0);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home),
              ],
            ),
          ),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              widget.onTap(1);
              _navigateToPage(1);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pie_chart),
              ],
            ),
          ),
          label: 'Statistics',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              widget.onTap(2);
              _navigateToPage(2);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note),
              ],
            ),
          ),
          label: 'Activity',
        ),
        BottomNavigationBarItem(
          icon: GestureDetector(
            onTap: () {
              widget.onTap(3);
              _navigateToPage(3);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person),
              ],
            ),
          ),
          label: 'Profile',
        ),
      ],
    );
  }
}
