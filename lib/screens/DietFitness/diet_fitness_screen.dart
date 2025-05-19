import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/model/df_tracker_model.dart';
import 'package:wellbotapp/responsive.dart';
import 'package:wellbotapp/screens/DietFitness/df_tracker/df_provider.dart';
import 'package:wellbotapp/screens/DietFitness/df_tracker/df_tracker_screen.dart';
import 'package:wellbotapp/screens/DietFitness/recommendation_form.dart';

class DietFitnessScreen extends StatefulWidget {
  @override
  _DietFitnessScreenState createState() => _DietFitnessScreenState();
}

class _DietFitnessScreenState extends State<DietFitnessScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _savedPlan;
  bool _isLoadingPlan = true;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSavedPlan();

    WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<TrackingProvider>(context, listen: false).loadWeeklyData();
  });
  }

  Future<void> _loadSavedPlan() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final doc = await _firestore.collection('user_plans').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _savedPlan = doc.data();
          _isLoadingPlan = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading plan: $e')),
      );
    }
  }

  Widget _buildFeatureContent(BuildContext context, {bool isDesktop = false}) {
    return Consumer<TrackingProvider>(
      builder: (context, trackingProvider, _) {
        return ListView(
          children: [
            if (_savedPlan != null) _buildSavedPlanSection(trackingProvider),
            const SizedBox(height: 20),
            _buildWeeklyProgress(trackingProvider),
          ],
        );
      },
    );
  }

  Widget _buildSavedPlanSection(TrackingProvider trackingProvider) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Current Plan', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          _buildTrackerSection(trackingProvider),
          const SizedBox(height: 20),
          const Text('Diet Plan Overview', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...(_savedPlan!['diet_plan'] as List).take(3).map((point) => 
              Text('- $point')),
          const SizedBox(height: 10),
          const Text('Fitness Plan Overview', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...(_savedPlan!['fitness_plan'] as List).take(3).map((point) => 
              Text('- $point')),
          const SizedBox(height: 10),
          // Add sleep data summary
          const Text('Sleep Recommendations', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('- Aim for 7-9 hours nightly'),
        ],
      ),
    ),
  );
}

  Widget _buildTrackerSection(TrackingProvider trackingProvider) {
  final todayData = trackingProvider.todayData;
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrackerItem(
            Icons.fitness_center,
            'Exercises',
            '${todayData.exercisesCompleted.where((e) => e).length}/5',
            Colors.green,
          ),
          _buildTrackerItem(
            Icons.local_dining,
            'Calories',
            '${todayData.calories}kcal',
            Colors.orange,
          ),
          _buildTrackerItem(
            Icons.water_drop,
            'Water',
            '${todayData.waterGlasses} glasses',
            Colors.blue,
          ),
          // Add sleep tracker item
          _buildTrackerItem(
            Icons.bedtime,
            'Sleep',
            '${todayData.hoursSlept.toStringAsFixed(1)}h',
            Colors.purple,
          ),
        ],
      ),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        icon: const Icon(Icons.track_changes),
        label: const Text('Daily Tracking'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyTrackerScreen()),
        ),
      ),
    ],
  );
}

  Widget _buildTrackerItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color)),
        const SizedBox(height: 4),
        Text(value, 
            style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildWeeklyProgress(TrackingProvider trackingProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly Progress', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: trackingProvider.weeklyData.length,
                itemBuilder: (context, index) {
                  final data = trackingProvider.weeklyData[index];
                  return _buildDayProgress(data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayProgress(DailyData data) {
  return Container(
    width: 100,
    margin: const EdgeInsets.only(right: 10),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('EEE').format(data.date),
          style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${data.waterGlasses}💧', style: const TextStyle(fontSize: 18)),
        Text('${data.calories}🔥', style: const TextStyle(fontSize: 18)),
        Text('${data.hoursSlept.toStringAsFixed(1)}🌙', 
          style: const TextStyle(fontSize: 18)),
        Icon(
          data.exercisesCompleted.contains(true) 
              ? Icons.check_circle 
              : Icons.circle_outlined,
          color: data.exercisesCompleted.contains(true)
              ? Colors.green
              : Colors.grey),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Diet & Fitness', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserDetailsFormScreen()),
            ),
          ),
        ],
      ),
      body: Background(
        child: Responsive(
          mobile: _buildFeatureContent(context),
          tablet: _buildFeatureContent(context),
          desktop: _buildFeatureContent(context, isDesktop: true),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }
}