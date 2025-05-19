import 'package:flutter/material.dart';
import 'package:wellbotapp/screens/DietFitness/recommendation_screen.dart';

class UserDetailsFormScreen extends StatefulWidget {
  @override
  _UserDetailsFormScreenState createState() => _UserDetailsFormScreenState();
}

class _UserDetailsFormScreenState extends State<UserDetailsFormScreen> {
  String _age = '';
  String _weight = '';
  String _height = '';
  String _goal = '';
  String _activityLevel = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Plan'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Enter Your Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: const InputDecoration(labelText: 'Age (years)'),
                  onChanged: (value) => _age = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  onChanged: (value) => _weight = value,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  onChanged: (value) => _height = value,
                ),
                TextField(
                  decoration:
                      const InputDecoration(labelText: 'Goal (e.g., Lose weight)'),
                  onChanged: (value) => _goal = value,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Activity Level'),
                  items: const [
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                    DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'High', child: Text('High')),
                  ],
                  onChanged: (value) => _activityLevel = value ?? '',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (_age.isNotEmpty &&
                        _weight.isNotEmpty &&
                        _height.isNotEmpty &&
                        _goal.isNotEmpty &&
                        _activityLevel.isNotEmpty) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecommendationScreen(
                            age: _age,
                            weight: _weight,
                            height: _height,
                            goal: _goal,
                            activityLevel: _activityLevel,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all the fields')),
                      );
                    }
                  },
                  child: const Text('Get Recommendations'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}