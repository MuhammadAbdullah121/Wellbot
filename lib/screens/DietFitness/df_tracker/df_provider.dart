// tracking_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellbotapp/model/df_tracker_model.dart';

extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

class TrackingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<DailyData> _weeklyData = [];
  DailyData _todayData = DailyData.empty();

  List<DailyData> get weeklyData => _weeklyData;
  DailyData get todayData => _todayData;

  TrackingProvider() {
    loadWeeklyData();
  }

   Future<void> loadWeeklyData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final snapshot = await _firestore.collection('daily_tracking')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: weekAgo)
        .orderBy('date', descending: true)
        .get();

    _weeklyData = snapshot.docs.map((doc) => DailyData.fromFirestore(doc)).toList();
    _todayData = _weeklyData.firstWhere(
      (data) => data.date.isSameDate(DateTime.now()),
      orElse: () => DailyData.empty(),
    );
    
    notifyListeners();
  }

Future<void> updateWater(int glasses) async {
  _todayData = _todayData.copyWith(waterGlasses: glasses);
  await _saveData();
  notifyListeners(); // Explicit notification
}

Future<void> updateSleep(double hours) async {
  _todayData = _todayData.copyWith(hoursSlept: hours);
  await _saveData();
  notifyListeners(); // Explicit notification
}


//   Future<void> updateWater(int glasses) async {
//   if (glasses < 0) return;
//   _todayData = _todayData.copyWith(waterGlasses: glasses);
//   await _saveData();
// }


//   Future<void> updateSleep(double hours) async {
//     _todayData = _todayData.copyWith(hoursSlept: hours);
//     await _saveData();
//   }

  Future<void> updateCalories(int calories) async {
    _todayData = _todayData.copyWith(calories: calories);
    await _saveData();
  }

  Future<void> toggleExercise(int index) async {
    final newExercises = List<bool>.from(_todayData.exercisesCompleted);
    newExercises[index] = !newExercises[index];
    _todayData = _todayData.copyWith(exercisesCompleted: newExercises);
    await _saveData();
  }

// Future<void> _saveData() async {
//   try {
//     final user = _auth.currentUser;
//     if (user == null) return;

//     final docRef = _firestore.collection('daily_tracking').doc(_todayData.id.isEmpty 
//         ? FirebaseFirestore.instance.collection('daily_tracking').doc().id 
//         : _todayData.id);

//     await docRef.set(_todayData.toFirestore(), SetOptions(merge: true));
    
//     // Update ID after first save
//     _todayData = _todayData.copyWith(id: docRef.id);
    
//     // Rest of your existing update logic...
//   } catch (e) {
//     print('Error saving data: $e');
//   }
// }

Future<void> _saveData() async {
  try {
    // Immediate UI update
    notifyListeners();
    
    // Firestore operations
    final docRef = _firestore.collection('daily_tracking').doc(_todayData.id);
    await docRef.set(_todayData.toFirestore(), SetOptions(merge: true));
    
    // Update local data
    final index = _weeklyData.indexWhere((d) => d.id == _todayData.id);
    if (index >= 0) {
      _weeklyData[index] = _todayData;
    } else {
      _weeklyData.insert(0, _todayData);
    }
    
    notifyListeners(); // Final update
  } catch (e) {
    print('Error saving data: $e');
  }
}

}