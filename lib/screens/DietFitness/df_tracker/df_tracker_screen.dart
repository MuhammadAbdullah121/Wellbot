import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wellbotapp/model/df_tracker_model.dart';
import 'package:wellbotapp/screens/DietFitness/df_tracker/df_provider.dart';
import 'package:wellbotapp/screens/DietFitness/diet_fitness_screen.dart';

class DailyTrackerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, provider, _) {
        // Always get fresh data from provider
        final data = provider.todayData;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Daily Tracker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _showWeeklySummary(context),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildWaterTracker(context, data, provider),
                _buildSleepTracker(context, data, provider),
                _buildCalorieTracker(context, data, provider),
                _buildExerciseTracker(context, data, provider),
                _buildSaveButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterTracker(BuildContext context, DailyData data, TrackingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.water_drop),
              title: Text('Water Intake'),
              subtitle: Text('Glasses per day'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    provider.updateWater(data.waterGlasses - 1);
                    provider.loadWeeklyData(); // Force refresh
                  },
                ),
                Text('${data.waterGlasses}', 
                  style: const TextStyle(fontSize: 24)),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    provider.updateWater(data.waterGlasses + 1);
                    provider.loadWeeklyData(); // Force refresh
                  },
                ),
              ],
            ),
            LinearProgressIndicator(
              value: data.waterGlasses / 8,
              minHeight: 20,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade300),
            ),
          ],
        ),
      ),
    );
  }


    Widget _buildSleepTracker(BuildContext context, DailyData data, TrackingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.bedtime),
              title: Text('Sleep Duration'),
              subtitle: Text('Hours per night'),
            ),
            Slider(
              value: data.hoursSlept,
              min: 0,
              max: 24,
              divisions: 24,
              label: '${data.hoursSlept.toStringAsFixed(1)} hours',
              onChanged: (value) {
                provider.updateSleep(value);
                provider.loadWeeklyData(); // Force refresh
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCalorieTracker(BuildContext context, DailyData data, TrackingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.local_fire_department),
              title: Text('Calorie Intake'),
              subtitle: Text('Calories consumed today'),
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: data.calories.toDouble(),
                    min: 0,
                    max: 5000,
                    onChanged: (value) {
                      provider.updateCalories(value.toInt());
                      provider.loadWeeklyData(); // Force refresh
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('${data.calories} kcal',
                    style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildExerciseTracker(BuildContext context, DailyData data, TrackingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text('Exercises Completed'),
            ),
            Wrap(
              spacing: 8,
              children: List.generate(5, (index) => FilterChip(
                label: Text('Exercise ${index + 1}'),
                selected: data.exercisesCompleted[index],
                onSelected: (_) => provider.toggleExercise(index),
                checkmarkColor: Colors.white,
                selectedColor: Colors.green,
                labelStyle: TextStyle(
                  color: data.exercisesCompleted[index] 
                    ? Colors.white 
                    : Colors.black,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.save),
        label: const Text('Save Progress'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DietFitnessScreen()),
          );
        },
      ),
    );
  }

  void _showWeeklySummary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Weekly Summary'),
        content: Consumer<TrackingProvider>(
          builder: (context, provider, _) => SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: provider.weeklyData.map((data) => ListTile(
                title: Text(DateFormat('MMM dd').format(data.date)),
                subtitle: Text('Water: ${data.waterGlasses} glasses'),
                trailing: Text('${data.calories} kcal'),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}