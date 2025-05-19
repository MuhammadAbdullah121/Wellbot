import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/notifications/notification_manager.dart';
import 'package:wellbotapp/screens/HomeScreen/components/top_widgets.dart';
import 'package:wellbotapp/screens/HomeScreen/components/feature_buttons.dart';
import 'package:wellbotapp/screens/Welcome/welcome_screen.dart';
import 'package:wellbotapp/screens/notification.dart';
import 'package:wellbotapp/responsive.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  // bool _isDrawerOpen = false;
  final NotificationManager _notificationManager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _notificationManager.initializeNotifications();
    _notificationManager.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    _notificationManager.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45.0),
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0.0,
          centerTitle: true,
          title: Text(
            'Home',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, size: 22.0, color: Colors.white),
                // Notification badge
                if (_notificationManager.unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '${_notificationManager.unreadCount}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              // Navigate to notification page and mark all as read
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
              // Mark all notifications as read when returning from notification page
              _notificationManager.markAllAsRead();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 22.0, color: Colors.white),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                );
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
          ),
        ),
      ),
      body: Stack(
        children: [
          Background(
            child: Responsive(
              mobile: _buildMobileLayout(),
              tablet: _buildTabletLayout(),
              desktop: _buildDesktopLayout(),
            ),
          ),
        ],
      ),
      // floatingActionButton: ElevatedButton(
      //   onPressed: () {},
      //   style: ElevatedButton.styleFrom(
      //     shape: CircleBorder(),
      //     backgroundColor: Colors.blue[800],
      //     padding: EdgeInsets.all(16),
      //     elevation: 8.0,
      //   ),
      //   child: Icon(Icons.mic, color: Colors.white, size: 22.0),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TopWidgets(),
          SizedBox(height: 9.0),
          FeatureButtons(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          TopWidgets(),
          SizedBox(height: 12.0),
          FeatureButtons(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            child: TopWidgets(),
          ),
          FeatureButtons(),
        ],
      ),
    );
  }
}