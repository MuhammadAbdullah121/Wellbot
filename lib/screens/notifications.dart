// import 'package:flutter/material.dart';
// import 'package:toggle_switch/toggle_switch.dart';
// import 'package:wellbotapp/components/bottom_navigation_bar.dart';
// import 'package:wellbotapp/components/background.dart';
// import 'package:wellbotapp/responsive.dart';

// class NotificationsScreen extends StatefulWidget {
//   @override
//   _NotificationsScreenState createState() => _NotificationsScreenState();
// }

// class _NotificationsScreenState extends State<NotificationsScreen> {
//   int _currentIndex = 2; // Assuming notifications is at index 2
//   int _selectedToggleIndex = 0;

//   void _onTabTapped(int index) {
//     setState(() {
//       _currentIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(50.0),
//         child: AppBar(
//           backgroundColor: Colors.blue,
//           elevation: 0.0,
//           centerTitle: true,
//           title: Text(
//             'Notifications',
//             style: TextStyle(
//               fontSize: 20.0,
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
//           ),
//         ),
//       ),
//       body: Background(
//         child: Responsive(
//           mobile: _buildContent(context, isMobile: true),
//           tablet: _buildContent(context),
//           desktop: _buildContent(context, isDesktop: true),
//         ),
//       ),
//       floatingActionButton: ElevatedButton(
//         onPressed: () {},
//         style: ElevatedButton.styleFrom(
//           shape: CircleBorder(),
//           backgroundColor: Colors.blue[800],
//           padding: EdgeInsets.all(16),
//           elevation: 8.0,
//         ),
//         child: Icon(Icons.mic, color: Colors.white, size: 22.0),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _currentIndex,
//         onTap: _onTabTapped,
//       ),
//     );
//   }

//   Widget _buildContent(BuildContext context, {bool isMobile = false, bool isDesktop = false}) {
//     return Padding(
//       padding: EdgeInsets.symmetric(
//         horizontal: isDesktop ? 50.0 : 16.0,
//         vertical: isMobile ? 20.0 : 50.0,
//       ),
//       child: Column(
//         children: [
//           _buildToggleSwitch(),
//           SizedBox(height: 20.0),
//           Expanded(child: _buildNotificationContent()),
//         ],
//       ),
//     );
//   }

//   Widget _buildToggleSwitch() {
//     return Center(
//       child: ToggleSwitch(
//         initialLabelIndex: _selectedToggleIndex,
//         totalSwitches: 3,
//         labels: ['All', 'Unread', 'Important'],
//         activeBgColors: [
//           [Colors.blueGrey],
//           [Colors.blueGrey],
//           [Colors.blueGrey],
//         ],
//         inactiveBgColor: Colors.white,
//         activeFgColor: Colors.white,
//         inactiveFgColor: Colors.black,
//         onToggle: (index) {
//           setState(() {
//             _selectedToggleIndex = index!;
//           });
//         },
//         minWidth: 120.0,
//         customTextStyles: List.generate(
//           3,
//           (index) => TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
//         ),
//       ),
//     );
//   }

//   Widget _buildNotificationContent() {
//     switch (_selectedToggleIndex) {
//       case 0:
//         return _buildAllNotifications();
//       case 1:
//         return _buildUnreadNotifications();
//       case 2:
//         return _buildImportantNotifications();
//       default:
//         return _buildAllNotifications();
//     }
//   }

//   Widget _buildAllNotifications() {
//     return _buildNotificationList(['Welcome to WellBot!', 'Your weekly summary is ready.', 'Try new features now!']);
//   }

//   Widget _buildUnreadNotifications() {
//     return _buildNotificationList(['You have 3 new messages.', 'Goal reminder: Time to walk!']);
//   }

//   Widget _buildImportantNotifications() {
//     return _buildNotificationList(['Account alert: Backup your data.', 'Health check: Missed goal yesterday!']);
//   }

//   Widget _buildNotificationList(List<String> notifications) {
//     return ListView.separated(
//       itemCount: notifications.length,
//       separatorBuilder: (_, __) => Divider(),
//       itemBuilder: (context, index) {
//         return ListTile(
//           leading: Icon(Icons.notifications_active, color: Colors.blue[700]),
//           title: Text(notifications[index]),
//           subtitle: Text('Just now', style: TextStyle(fontSize: 12.0)),
//           trailing: Icon(Icons.chevron_right),
//           onTap: () {
//             // Handle notification tap
//           },
//         );
//       },
//     );
//   }
// }
