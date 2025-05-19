import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/screens/DietFitness/diet_fitness_screen.dart';
import 'package:wellbotapp/screens/time_management/time_management_screen.dart';
import 'package:wellbotapp/screens/MoneyManagement/money_management_screen.dart';
import 'package:wellbotapp/screens/social_helper_screen.dart';

class OngoingActivitiesPage extends StatefulWidget {
  @override
  _OngoingActivitiesPageState createState() => _OngoingActivitiesPageState();
}

class _OngoingActivitiesPageState extends State<OngoingActivitiesPage> {
  int _currentIndex = 2;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> activities = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadActivities();
  }

  Future<void> loadActivities() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        _fetchTimeManagement(),
        _fetchGoals(),
        _fetchFitnessData(),
        _fetchSocialProgress(),
      ]);

      final timeData = results[0] as Map<String, dynamic>;
      final goalsData = results[1] as List<Map<String, dynamic>>;
      final fitnessData = results[2] as Map<String, dynamic>;
      final socialData = results[3] as Map<String, dynamic>;

      // Transform Firebase data into activity items
      List<Map<String, dynamic>> firebaseActivities = [];

      // Time Management Activity
      if (timeData.isNotEmpty) {
        firebaseActivities.add({
          'title': timeData['taskTitle'] ?? 'Time Task',
          'description':
              'Hours Spent: ${timeData['hoursSpent']?.toStringAsFixed(1) ?? '0'}h',
          'type': 'Time Management',
          'status': 'In Progress',
          'priority': 'High',
          'screen': 'TimeManagement',
          'color': Colors.blue.shade100,
          'icon': Icons.access_time,
        });
      }

      // Financial Goals
      for (var goal in goalsData) {
        firebaseActivities.add({
          'title': goal['title'] ?? 'Financial Goal',
          'description':
              'Progress: ${goal['progress']?.toStringAsFixed(1) ?? '0'}%',
          'type': 'Money Management',
          'status':
              (goal['progress'] ?? 0) >= 100 ? 'Completed' : 'In Progress',
          'priority': 'High',
          'screen': 'MoneyManagement',
          'color': Colors.orange.shade100,
          'icon': Icons.flag,
        });
      }

      // Diet & Fitness
      if (fitnessData.isNotEmpty) {
        firebaseActivities.add({
          'title': 'Diet & Fitness',
          'description':
              'Calories: ${fitnessData['calories']} | Water: ${fitnessData['water']} glasses',
          'type': 'Diet & Fitness',
          'status': 'Active',
          'priority': 'Medium',
          'screen': 'DietFitness',
          'color': Colors.green.shade100,
          'icon': Icons.fitness_center,
        });
      }

      // Social Progress
      if (socialData.isNotEmpty) {
        firebaseActivities.add({
          'title': 'Social Progress',
          'description':
              'Affirmations: ${socialData['affirmations'] ? '✅' : '❌'} | Small Talk: ${socialData['smallTalk'] ? '✅' : '❌'}',
          'type': 'Social Helper',
          'status': 'Active',
          'priority': 'Medium',
          'screen': 'SocialHelper',
          'color': Colors.purple.shade100,
          'icon': Icons.people,
        });
      }

      setState(() {
        activities = firebaseActivities.isNotEmpty
            ? firebaseActivities
            : _getSampleActivities();
      });
    } catch (e) {
      print('Error loading activities: $e');
      setState(() {
        activities = _getSampleActivities();
      });
    }
    setState(() => isLoading = false);
  }

  // Data Fetching Functions
  Future<Map<String, dynamic>> _fetchTimeManagement() async {
    try {
      final doc = await _firestore
          .collection('time_manage')
          .where('userId', isEqualTo: _user?.uid)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) {
        // Hardcoded fallback data
        return {
          'taskTitle': 'Prepare for Exams',
          'hoursSpent': 12.5,
        };
      }

      final data = doc.docs.first.data();
      final tasks = List<Map<String, dynamic>>.from(data['tasks'] ?? []);
      final timeSpent = Map<String, dynamic>.from(data['timeSpent'] ?? {});

      // Find first incomplete task (handle map structure)
      Map<String, dynamic> activeTask = {'title': 'No active task'};
      for (var task in tasks) {
        final status = task['completionStatus'] is Map
            ? task['completionStatus']['completed'] ?? false
            : task['completionStatus'] ?? false;

        if (status == false) {
          activeTask = task;
          break;
        }
      }

      double totalHours = 0.0;
      final taskId = activeTask['id']?.toString() ?? '';

      if (timeSpent.containsKey(taskId)) {
        final entries =
            List<Map<String, dynamic>>.from(timeSpent[taskId] ?? []);
        totalHours = entries.fold(
            0.0, (sum, entry) => sum + (entry['hoursSpent'] ?? 0).toDouble());
      }

      // Fallback to hardcoded data if no hours found
      if (totalHours == 0.0) {
        totalHours = 8.0; // Default hours
      }

      return {
        'taskTitle': activeTask['title'] ?? 'Prepare for Exams',
        'hoursSpent': totalHours,
      };
    } catch (e) {
      print('Error fetching time data: $e');
      // Return hardcoded data on error
      return {
        'taskTitle': 'Study Session',
        'hoursSpent': 4.5,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _fetchGoals() async {
    try {
      final snapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: _user?.uid)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final current = (data['currentAmount'] ?? 0).toDouble();
        final total = (data['finalAmount'] ?? 1).toDouble();
        return {
          'title': data['title'] ?? 'Untitled Goal',
          'progress': (current / total) * 100,
        };
      }).toList();
    } catch (e) {
      print('Error fetching goals: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> _fetchFitnessData() async {
    try {
      final doc = await _firestore
          .collection('daily_tracking')
          .where('userId', isEqualTo: _user?.uid)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return {};

      final data = doc.docs.first.data();
      return {
        'calories': data['calories'] ?? 0,
        'water': data['water'] ?? 0,
        'exercises': (data['exercises'] as List).where((e) => e == true).length,
      };
    } catch (e) {
      print('Error fetching fitness data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchSocialProgress() async {
    try {
      final doc = await _firestore
          .collection('social_progress')
          .where('userId', isEqualTo: _user?.uid)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return {};

      final data = doc.docs.first.data();
      return {
        'affirmations': data['affirmationCompleted'] ?? false,
        'smallTalk': data['smallTalkCompleted'] ?? false,
      };
    } catch (e) {
      print('Error fetching social data: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> _getSampleActivities() {
    return [
      {
        'title': 'Project Deadline',
        'description': 'Hours Spent: 8.5h',
        'type': 'Time Management',
        'status': 'In Progress',
        'priority': 'High',
        'screen': 'TimeManagement',
        'color': Colors.blue.shade100,
        'icon': Icons.access_time,
      },
      {
        'title': 'Savings Target',
        'description': 'Progress: 65.5%',
        'type': 'Money Management',
        'status': 'In Progress',
        'priority': 'High',
        'screen': 'MoneyManagement',
        'color': Colors.orange.shade100,
        'icon': Icons.flag,
      },
      {
        'title': 'Daily Fitness',
        'description': 'Calories: 2100 | Water: 6 glasses',
        'type': 'Diet & Fitness',
        'status': 'Active',
        'priority': 'Medium',
        'screen': 'DietFitness',
        'color': Colors.green.shade100,
        'icon': Icons.fitness_center,
      },
      {
        'title': 'Social Activities',
        'description': 'Affirmations: ✅ | Small Talk: ❌',
        'type': 'Social Helper',
        'status': 'Active',
        'priority': 'Medium',
        'screen': 'SocialHelper',
        'color': Colors.purple.shade100,
        'icon': Icons.people,
      },
    ];
  }

  Future<void> clearAllActivities() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Activities'),
          content: Text('Are you sure you want to clear all activities?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                setState(() => activities = []);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Displayed activities cleared'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Clear', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void navigateToScreen(String screen) {
    Widget targetScreen;

    switch (screen) {
      case 'TimeManagement':
        targetScreen = TimeManagementScreen();
        break;
      case 'DietFitness':
        targetScreen = DietFitnessScreen();
        break;
      case 'MoneyManagement':
        targetScreen = MoneyManagementScreen();
        break;
      case 'SocialHelper':
        targetScreen = SocialHelperScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    ).then((_) => loadActivities());
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
      case 'active':
        return Colors.blue;
      case 'pending':
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    int highPriorityCount =
        activities.where((a) => a['priority'] == 'High').length;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(45.0),
        child: AppBar(
          backgroundColor: Colors.blue,
          title: Text(
            'Ongoing Activities',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: loadActivities,
            ),
            IconButton(
              icon: Icon(Icons.clear_all, color: Colors.white),
              onPressed: clearAllActivities,
            ),
          ],
        ),
      ),
      body: Background(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  SizedBox(height: 10),
                  // Summary Card
                  Container(
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${activities.length}',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total Activities',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        VerticalDivider(color: Colors.white30, width: 1),
                        Column(
                          children: [
                            Text(
                              '$highPriorityCount',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'High Priority',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10),
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: activities.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_outlined,
                                      size: 80, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No activities found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Data will appear when you add activities',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: activities.length,
                              itemBuilder: (context, index) {
                                final activity = activities[index];
                                return Container(
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: activity['color'],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(activity['icon'],
                                          color: Colors.black87),
                                    ),
                                    title: Text(activity['title'],
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(activity['description']),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Chip(
                                              label: Text(activity['type']),
                                              backgroundColor:
                                                  activity['color'],
                                            ),
                                            Spacer(),
                                            Chip(
                                              label: Text(activity['status']),
                                              backgroundColor: _getStatusColor(
                                                      activity['status'])
                                                  .withOpacity(0.2),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.blue),
                                    onTap: () =>
                                        navigateToScreen(activity['screen']),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
      ),
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
}
