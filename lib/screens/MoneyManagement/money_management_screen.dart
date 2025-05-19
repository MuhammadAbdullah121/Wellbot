import 'package:flutter/material.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/constants.dart';
import 'package:wellbotapp/screens/MoneyManagement/expense_tracking.dart';
import 'package:wellbotapp/screens/MoneyManagement/goal_setting.dart';

class MoneyManagementScreen extends StatefulWidget {
  const MoneyManagementScreen({super.key});

  @override
  _MoneyManagementScreenState createState() => _MoneyManagementScreenState();
}

class _MoneyManagementScreenState extends State<MoneyManagementScreen> {
  int _currentIndex = 0;
  String selectedSegment = 'Expense Tracking';

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child:AppBar(
          backgroundColor: Colors.blue,
          elevation: 0.0,
          centerTitle: true,
          title: const Text(
            'Money Management',
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
          ),
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.settings),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => MoneySettingsScreen()),
          //       );
          //     },
          //   ),
          // ],
        ),
      ),
      body: Background(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SegmentedButton(
                segments: const ['Expense Tracking', 'Financial Goal'],
                selectedSegment: selectedSegment,
                onSegmentChanged: (segment) {
                  setState(() {
                    selectedSegment = segment;
                  });
                },
              ),
            ),
            Expanded(
              child: selectedSegment == 'Expense Tracking'
                  ? ExpenseTrackingScreen()
                  : GoalSettingScreen(),
            ),
          ],
        ),
      ),
      // floatingActionButton: ElevatedButton(
      //   onPressed: () {},
      //   style: ElevatedButton.styleFrom(
      //     shape: const CircleBorder(),
      //     backgroundColor: Colors.blue[800],
      //     padding: const EdgeInsets.all(16),
      //     elevation: 8.0,
      //   ),
      //   child: const Icon(Icons.mic, color: Colors.white, size: 22.0),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}

class SegmentedButton extends StatelessWidget {
  final List<String> segments;
  final String selectedSegment;
  final ValueChanged<String> onSegmentChanged;

  const SegmentedButton({
    required this.segments,
    required this.selectedSegment,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: segments.map((segment) {
        final isSelected = segment == selectedSegment;
        return GestureDetector(
          onTap: () => onSegmentChanged(segment),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: isSelected ? kPrimaryColor : Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              segment,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
