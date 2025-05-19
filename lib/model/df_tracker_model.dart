// df_tracker_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@immutable
class DailyData {
  final String id;
  final DateTime date;
  final int waterGlasses;
  final double hoursSlept;
  final int calories;
  final List<bool> exercisesCompleted;
  final bool isCompleted;

  const DailyData({
    required this.id,
    required this.date,
    required this.waterGlasses,
    required this.hoursSlept,
    required this.calories,
    required this.exercisesCompleted,
    required this.isCompleted,
  });

factory DailyData.empty() => DailyData(
  id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
  date: DateTime.now(),
  waterGlasses: 0,
  hoursSlept: 0.0, // Ensure double type
  calories: 0,
  exercisesCompleted: List<bool>.filled(5, false),
  isCompleted: false,
);

  factory DailyData.fromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>;
  return DailyData(
    id: doc.id,
    date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    waterGlasses: (data['water'] as int?) ?? 0,
    hoursSlept: (data['hoursSlept'] as num?)?.toDouble() ?? 0.0,
    calories: (data['calories'] as int?) ?? 0,
    exercisesCompleted: List<bool>.from(data['exercises'] ?? []),
    isCompleted: (data['isCompleted'] as bool?) ?? false,
  );
}

  DailyData copyWith({
    String? id,
    DateTime? date,
    int? waterGlasses,
    double? hoursSlept,
    int? calories,
    List<bool>? exercisesCompleted,
    bool? isCompleted,
  }) => DailyData(
    id: id ?? this.id,
    date: date ?? this.date,
    waterGlasses: waterGlasses ?? this.waterGlasses,
    hoursSlept: hoursSlept ?? this.hoursSlept,
    calories: calories ?? this.calories,
    exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
    isCompleted: isCompleted ?? this.isCompleted,
  );

  Map<String, dynamic> toFirestore() => {
    'date': Timestamp.fromDate(date),
    'water': waterGlasses,
    'hoursSlept': hoursSlept,
    'calories': calories,
    'exercises': exercisesCompleted,
    'isCompleted': isCompleted,
    'userId': FirebaseAuth.instance.currentUser?.uid,
  };
}