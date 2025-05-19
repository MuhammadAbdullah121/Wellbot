import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/constants.dart';

extension DayOfYear on DateTime {
  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays + 1;
  }
}

class SocialHelperScreen extends StatefulWidget {
  @override
  _SocialHelperScreenState createState() => _SocialHelperScreenState();
}

class _SocialHelperScreenState extends State<SocialHelperScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? get _currentUser => _auth.currentUser;

  final List<String> _affirmations = List.generate(
      55, (i) => "Affirmation ${i + 1}: You are ${['worthy', 'capable', 'enough'][i % 3]}!");
  final List<String> _affirmationTips = [
    "Say it in the mirror",
    "Repeat 3 times aloud",
    "Breathe deeply while saying it",
    "Write it down first",
    "Say it with a smile"
  ];

  final List<String> _smallTalkPrompts = List.generate(
      55, (i) => "Ask someone about their ${['weekend plans', 'favorite hobby', 'recent vacation'][i % 3]}");
  final List<String> _conversationTips = [
    "Start with eye contact",
    "Use open-ended questions",
    "Nod to show interest",
    "Mirror their body language",
    "Share a related experience"
  ];

  int _affirmationIndex = 0;
  int _smallTalkIndex = 0;
  String _affirmationTip = '';
  String _conversationTip = '';
  bool _affirmationCompleted = false;
  bool _smallTalkCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _resetToDefault() {
    if (mounted) {
      setState(() {
        _affirmationIndex = 0;
        _smallTalkIndex = 0;
        _affirmationTip = _affirmationTips.first;
        _conversationTip = _conversationTips.first;
        _affirmationCompleted = false;
        _smallTalkCompleted = false;
      });
    }
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();

      if (_currentUser == null) {
        await _handleUnauthenticatedUser(prefs, today);
        return;
      }

      final docRef = _firestore
          .collection('social_progress')
          .doc('${_currentUser!.uid}_${_getDateKey(today)}');

      final docSnapshot = await docRef.get();

      final shouldReset = await _needsReset(prefs, today);

      if (shouldReset || !docSnapshot.exists) {
        await _generateNewContent(today);
      } else {
        final firebaseData = docSnapshot.data()!;
        setState(() {
          _affirmationIndex = firebaseData['affirmationIndex'] ?? 0;
          _smallTalkIndex = firebaseData['smallTalkIndex'] ?? 0;
          _affirmationCompleted = firebaseData['affirmationCompleted'] ?? false;
          _smallTalkCompleted = firebaseData['smallTalkCompleted'] ?? false;
        });

        await prefs.setInt('affirmationIndex', _affirmationIndex);
        await prefs.setInt('smallTalkIndex', _smallTalkIndex);
        await prefs.setBool('affirmationCompleted', _affirmationCompleted);
        await prefs.setBool('smallTalkCompleted', _smallTalkCompleted);
        await prefs.setString('lastUpdated', today.toIso8601String());

        final random = Random();
        setState(() {
          _affirmationTip = _affirmationTips[random.nextInt(_affirmationTips.length)];
          _conversationTip = _conversationTips[random.nextInt(_conversationTips.length)];
        });
      }
    } catch (e) {
      print('Error loading state: $e');
      _resetToDefault();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _needsReset(SharedPreferences prefs, DateTime today) async {
    try {
      final lastDate = prefs.getString('lastUpdated');
      if (lastDate == null) return true;
      final lastDateTime = DateTime.parse(lastDate);
      return lastDateTime.day != today.day ||
          lastDateTime.month != today.month ||
          lastDateTime.year != today.year;
    } catch (e) {
      print('Error checking reset: $e');
      return true;
    }
  }

  Future<void> _generateNewContent(DateTime today) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final random = Random();

      final newAffirmationIndex = random.nextInt(_affirmations.length);
      final newSmallTalkIndex = today.dayOfYear % _smallTalkPrompts.length;
      final newAffirmationTip = _affirmationTips[random.nextInt(_affirmationTips.length)];
      final newConversationTip = _conversationTips[random.nextInt(_conversationTips.length)];

      if (mounted) {
        setState(() {
          _affirmationIndex = newAffirmationIndex;
          _smallTalkIndex = newSmallTalkIndex;
          _affirmationTip = newAffirmationTip;
          _conversationTip = newConversationTip;
          _affirmationCompleted = false;
          _smallTalkCompleted = false;
        });
      }

      if (_currentUser != null) {
        await _firestore
            .collection('social_progress')
            .doc('${_currentUser!.uid}_${_getDateKey(today)}')
            .set({
          'userId': _currentUser!.uid,
          'date': _getDateKey(today),
          'affirmationIndex': _affirmationIndex,
          'smallTalkIndex': _smallTalkIndex,
          'affirmationCompleted': false,
          'smallTalkCompleted': false,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await prefs.setInt('affirmationIndex', _affirmationIndex);
      await prefs.setInt('smallTalkIndex', _smallTalkIndex);
      await prefs.setString('lastUpdated', today.toIso8601String());
      await prefs.setBool('affirmationCompleted', false);
      await prefs.setBool('smallTalkCompleted', false);
    } catch (e) {
      print('Error generating new content: $e');
      _resetToDefault();
    }
  }

  Future<void> _markComplete(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();

      if (mounted) {
        setState(() {
          if (type == 'affirmation') _affirmationCompleted = true;
          if (type == 'smalltalk') _smallTalkCompleted = true;
        });
      }

      if (_currentUser != null) {
        await _firestore
            .collection('social_progress')
            .doc('${_currentUser!.uid}_${_getDateKey(today)}')
            .set({
          '${type}Completed': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await prefs.setBool('${type}Completed', true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Progress saved successfully!')),
      );
    } catch (e) {
      print('Error marking complete: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save progress. Please try again.')),
      );
    }
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  Future<void> _handleUnauthenticatedUser(SharedPreferences prefs, DateTime today) async {
    try {
      final random = Random();
      if (await _needsReset(prefs, today)) {
        if (mounted) {
          setState(() {
            _affirmationIndex = random.nextInt(_affirmations.length);
            _smallTalkIndex = today.dayOfYear % _smallTalkPrompts.length;
            _affirmationTip = _affirmationTips[random.nextInt(_affirmationTips.length)];
            _conversationTip = _conversationTips[random.nextInt(_conversationTips.length)];
            _affirmationCompleted = false;
            _smallTalkCompleted = false;
          });
        }

        await prefs.setInt('affirmationIndex', _affirmationIndex);
        await prefs.setInt('smallTalkIndex', _smallTalkIndex);
        await prefs.setString('lastUpdated', today.toIso8601String());
        await prefs.setBool('affirmationCompleted', false);
        await prefs.setBool('smallTalkCompleted', false);
      } else {
        if (mounted) {
          setState(() {
            _affirmationIndex = prefs.getInt('affirmationIndex') ?? 0;
            _smallTalkIndex = prefs.getInt('smallTalkIndex') ?? 0;
            _affirmationCompleted = prefs.getBool('affirmationCompleted') ?? false;
            _smallTalkCompleted = prefs.getBool('smallTalkCompleted') ?? false;
            _affirmationTip = _affirmationTips[random.nextInt(_affirmationTips.length)];
            _conversationTip = _conversationTips[random.nextInt(_conversationTips.length)];
          });
        }
      }
    } catch (e) {
      print('Error handling unauthenticated user: $e');
      _resetToDefault();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Social Confidence Builder'),
        backgroundColor: kPrimaryColor,
      ),
      body: Background(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(defaultPadding),
                child: Column(
                  children: [
                    _buildAffirmationCard(),
                    SizedBox(height: defaultPadding),
                    _buildSmallTalkCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAffirmationCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Affirmation',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    )),
            SizedBox(height: defaultPadding),
            Text(_affirmations[_affirmationIndex], style: TextStyle(fontSize: 16, height: 1.5)),
            SizedBox(height: 12),
            _buildTipBox(_affirmationTip),
            SizedBox(height: defaultPadding),
            _buildActionButton(
              isCompleted: _affirmationCompleted,
              icon: Icons.mic,
              label: 'Mark as Spoken',
              onPressed: () => _markComplete('affirmation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTalkCard() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Small Talk Challenge',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    )),
            SizedBox(height: defaultPadding),
            Text(_smallTalkPrompts[_smallTalkIndex], style: TextStyle(fontSize: 16, height: 1.5)),
            SizedBox(height: 12),
            _buildTipBox(_conversationTip),
            SizedBox(height: defaultPadding),
            _buildActionButton(
              isCompleted: _smallTalkCompleted,
              icon: Icons.chat,
              label: 'I Tried This Today',
              onPressed: () => _markComplete('smalltalk'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipBox(String text) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber[700]),
          SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[800]))),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required bool isCompleted,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(isCompleted ? Icons.check : icon),
        label: Text(isCompleted ? 'Completed Today' : label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? Colors.green : kPrimaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: isCompleted ? null : onPressed,
      ),
    );
  }
}
