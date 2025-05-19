import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:wellbotapp/components/background.dart';

class RecommendationScreen extends StatefulWidget {
  final String age;
  final String weight;
  final String height;
  final String goal;
  final String activityLevel;

  RecommendationScreen({
    required this.age,
    required this.weight,
    required this.height,
    required this.goal,
    required this.activityLevel,
  });

  @override
  _RecommendationScreenState createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<String> _dietPlan = [];
  List<String> _fitnessPlan = [];
  bool _showDietPlan = true;
  bool _isLoading = false;
   bool _isSaving = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

    // Add this new method
  Future<void> _savePlanToFirebase() async {
    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('user_plans').doc(user.uid).set({
        'diet_plan': _dietPlan,
        'fitness_plan': _fitnessPlan,
        'timestamp': FieldValue.serverTimestamp(),
        'user_details': {
          'age': widget.age,
          'weight': widget.weight,
          'height': widget.height,
          'goal': widget.goal,
          'activity': widget.activityLevel,
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving plan: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }



  Future<void> _fetchRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    final apiKey = 'AIzaSyCxlb7pIUnNk2D1HHvRA5JOMjl4znn-5jg';
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
    final promptDiet =
        "As a professional nutritionist, create a personalized diet plan for someone who is ${widget.age} years old, weighs ${widget.weight} kg, is ${widget.height} cm tall, wants to ${widget.goal}, and has a ${widget.activityLevel} activity level. Write it in a natural, conversational tone as if you're speaking directly to the person. Include these sections: 1) Daily Caloric Needs - explain their daily calorie requirements and why, 2) Meal Planning - provide a practical meal schedule, 3) Food Recommendations - suggest specific foods and explain their benefits, 4) Hydration Guidelines - explain water intake needs and tips, 5) Lifestyle Tips - share practical advice for maintaining the diet, 6) Important Notes - provide key reminders and safety considerations. Write in a friendly, expert tone without any AI-like formatting.";
    final promptFitness =
        "As a professional fitness trainer, create a personalized workout plan for someone who is ${widget.age} years old, weighs ${widget.weight} kg, is ${widget.height} cm tall, wants to ${widget.goal}, and has a ${widget.activityLevel} activity level. Write it in a natural, motivational tone as if you're speaking directly to the person. Include these sections: 1) Weekly Exercise Schedule - outline a practical weekly routine, 2) Workout Routines - describe specific exercises and their benefits, 3) Exercise Guidelines - explain proper form and safety tips, 4) Recovery Tips - provide advice on rest and recovery, 5) Progress Tracking - suggest ways to monitor improvement, 6) Important Notes - provide key reminders and safety considerations. Write in an encouraging, expert tone without any AI-like formatting.";

    try {
      final responseDiet = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": promptDiet}
              ]
            }
          ]
        }),
      );

      final responseFitness = await http.post(
        Uri.parse('$url?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": promptFitness}
              ]
            }
          ]
        }),
      );

      setState(() {
        _dietPlan = _extractSuggestions(responseDiet);
        _fitnessPlan = _extractSuggestions(responseFitness);
      });
    } catch (e) {
      setState(() {
        _dietPlan = ['Error: $e'];
        _fitnessPlan = ['Error: $e'];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _extractSuggestions(http.Response response) {
    if (response.statusCode == 200) {
      try {
        final rawText = jsonDecode(response.body)['candidates'][0]['content']
            ['parts'][0]['text'];

        if (rawText is String) {
          // Enhanced text cleaning and formatting
          final cleanedText = rawText
              .replaceAll(RegExp(r'[*#_~`]'), '') // Remove markdown characters
              .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
              .replaceAll(RegExp(r'^\s*[-•*]\s*'), '') // Remove bullet points
              .replaceAll(RegExp(r'^\d+\.\s*'), '') // Remove numbered lists
              .replaceAll(
                  RegExp(
                      r'As an AI|As a language model|Generated by|AI-generated'),
                  '') // Remove AI references
              .trim();

          // Split into sections based on section titles
          final sections = cleanedText
              .split(RegExp(
                  r'(?=Daily Caloric Needs|Meal Planning|Food Recommendations|Hydration Guidelines|Lifestyle Tips|Weekly Exercise Schedule|Workout Routines|Exercise Guidelines|Recovery Tips|Progress Tracking)'))
              .where((e) => e.isNotEmpty)
              .map((e) => e.trim())
              .toList();

          // Remove section titles from the content
          return sections.map((section) {
            return section.replaceAll(
                RegExp(
                    r'^(Daily Caloric Needs|Meal Planning|Food Recommendations|Hydration Guidelines|Lifestyle Tips|Weekly Exercise Schedule|Workout Routines|Exercise Guidelines|Recovery Tips|Progress Tracking):?\s*'),
                '');
          }).toList();
        } else {
          return ['Unexpected data format'];
        }
      } catch (e) {
        return ['Error parsing response: $e'];
      }
    }
    return ['Failed to fetch data'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _savePlanToFirebase,
        child: _isSaving 
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.save),
      ),
      appBar: AppBar(
        title: const Text('Your Personalized Plan'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Your Plan'),
                  content: const Text(
                      'This personalized plan has been carefully crafted based on your specific details and goals. Follow the recommendations consistently for best results.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Background(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ToggleButtons(
                      isSelected: [_showDietPlan, !_showDietPlan],
                      onPressed: (index) {
                        setState(() {
                          _showDietPlan = index == 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(10),
                      borderColor: Colors.blue.shade800,
                      selectedBorderColor: Colors.blue.shade800,
                      fillColor: Colors.blue.shade50,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant_menu, size: 20),
                              SizedBox(width: 8),
                              Text('Diet Plan'),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fitness_center, size: 20),
                              SizedBox(width: 8),
                              Text('Fitness Plan'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _showDietPlan
                                        ? Icons.restaurant_menu
                                        : Icons.fitness_center,
                                    color: Colors.blue.shade800,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _showDietPlan
                                        ? 'Your Personalized Diet Plan'
                                        : 'Your Personalized Fitness Plan',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ...(_showDietPlan ? _dietPlan : _fitnessPlan)
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final section = entry.value;
                                final sectionTitle = _showDietPlan
                                    ? _getDietSectionTitle(index)
                                    : _getFitnessSectionTitle(index);

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        sectionTitle,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      section,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.6,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _getDietSectionTitle(int index) {
    switch (index) {
      case 0:
        return 'Daily Caloric Needs';
      case 1:
        return 'Meal Planning';
      case 2:
        return 'Food Recommendations';
      case 3:
        return 'Hydration Guidelines';
      case 4:
        return 'Lifestyle Tips';
      case 5:
        return 'Important Notes';
      default:
        return 'Section ${index + 1}';
    }
  }

  String _getFitnessSectionTitle(int index) {
    switch (index) {
      case 0:
        return 'Weekly Exercise Schedule';
      case 1:
        return 'Workout Routines';
      case 2:
        return 'Exercise Guidelines';
      case 3:
        return 'Recovery Tips';
      case 4:
        return 'Progress Tracking';
      case 5:
        return 'Important Notes';
      default:
        return 'Section ${index + 1}';
    }
  }
}
