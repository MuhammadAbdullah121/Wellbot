import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimeManagementService {
  static const String _tasksKey = 'tasks';
  static const String _timeSpentKey = 'time_spent';
  static const String _completionStatusKey = 'completion_status';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final TimeManagementService _instance = TimeManagementService._internal();
  factory TimeManagementService() => _instance;
  TimeManagementService._internal();

  // Cache for tasks
  List<Map<String, dynamic>>? _tasksCache;
  Map<String, List<Map<String, dynamic>>>? _timeSpentCache;
  Map<String, bool>? _completionStatusCache;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<List<Map<String, dynamic>>> getTasks() async {
    if (_tasksCache != null) return _tasksCache!;

    // Get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString(_tasksKey);
    
    // Get from Firestore
    final doc = await _firestore.collection('time_manage').doc(_userId).get();
    final firestoreTasks = doc.exists ? (doc.data()?['tasks'] as List?)?.map((item) => Map<String, dynamic>.from(item)).toList() : null;

    // Prefer Firestore data if available, fallback to SharedPreferences
    if (firestoreTasks != null) {
      _tasksCache = firestoreTasks;
      // Sync to SharedPreferences
      await saveTasks(firestoreTasks);
      return firestoreTasks;
    }

    if (tasksJson == null) return [];

    final List<dynamic> decoded = json.decode(tasksJson);
    _tasksCache = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    return _tasksCache!;
  }

  Future<void> saveTasks(List<Map<String, dynamic>> tasks) async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = json.encode(tasks);
    await prefs.setString(_tasksKey, tasksJson);

    // Save to Firestore
    await _firestore.collection('time_manage').doc(_userId).set({
      'tasks': tasks,
    }, SetOptions(merge: true));

    _tasksCache = tasks;
  }

  Future<Map<String, List<Map<String, dynamic>>>> getTimeSpent() async {
    if (_timeSpentCache != null) return _timeSpentCache!;

    // Get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final timeSpentJson = prefs.getString(_timeSpentKey);

    // Get from Firestore
    final doc = await _firestore.collection('time_manage').doc(_userId).get();
    final firestoreTimeSpent = doc.exists ? (doc.data()?['timeSpent'] as Map?)?.map(
      (key, value) => MapEntry(key, (value as List).map((item) => Map<String, dynamic>.from(item)).toList())
    ) : null;

    // Prefer Firestore data if available
    if (firestoreTimeSpent != null) {
      _timeSpentCache = firestoreTimeSpent.cast<String, List<Map<String, dynamic>>>();
      // Sync to SharedPreferences
      await saveTimeSpent(firestoreTimeSpent.cast<String, List<Map<String, dynamic>>>());
      return firestoreTimeSpent.cast<String, List<Map<String, dynamic>>>();
    }

    if (timeSpentJson == null) return {};

    final Map<String, dynamic> decoded = json.decode(timeSpentJson);
    _timeSpentCache = decoded.map((key, value) => MapEntry(
          key,
          (value as List).map((item) => Map<String, dynamic>.from(item)).toList(),
        ));
    return _timeSpentCache!;
  }

  Future<void> saveTimeSpent(Map<String, List<Map<String, dynamic>>> timeSpent) async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final timeSpentJson = json.encode(timeSpent);
    await prefs.setString(_timeSpentKey, timeSpentJson);

    // Save to Firestore
    await _firestore.collection('time_manage').doc(_userId).set({
      'timeSpent': timeSpent,
    }, SetOptions(merge: true));

    _timeSpentCache = timeSpent;
  }

  Future<Map<String, bool>> getCompletionStatus() async {
    if (_completionStatusCache != null) return _completionStatusCache!;

    // Get from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final statusJson = prefs.getString(_completionStatusKey);

    // Get from Firestore
    final doc = await _firestore.collection('time_manage').doc(_userId).get();
    final firestoreStatus = doc.exists ? (doc.data()?['completionStatus'] as Map?)?.map(
      (key, value) => MapEntry(key.toString(), value as bool)
    ) : null;

    // Prefer Firestore data if available
    if (firestoreStatus != null) {
      _completionStatusCache = firestoreStatus;
      // Sync to SharedPreferences
      await saveCompletionStatus(firestoreStatus);
      return firestoreStatus;
    }

    if (statusJson == null) return {};

    final Map<String, dynamic> decoded = json.decode(statusJson);
    _completionStatusCache = decoded.map((key, value) => MapEntry(key, value as bool));
    return _completionStatusCache!;
  }

  Future<void> saveCompletionStatus(Map<String, bool> completionStatus) async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final statusJson = json.encode(completionStatus);
    await prefs.setString(_completionStatusKey, statusJson);

    // Save to Firestore
    await _firestore.collection('time_manage').doc(_userId).set({
      'completionStatus': completionStatus,
    }, SetOptions(merge: true));

    _completionStatusCache = completionStatus;
  }

  // Clear all caches
  void clearCache() {
    _tasksCache = null;
    _timeSpentCache = null;
    _completionStatusCache = null;
  }

  // Clear all data
  Future<void> clearAllData() async {
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_timeSpentKey);
    await prefs.remove(_completionStatusKey);

    // Clear Firestore
    await _firestore.collection('time_manage').doc(_userId).delete();

    clearCache();
  }
}
