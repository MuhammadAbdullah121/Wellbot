import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellbotapp/model/time_manage.dart';

class TimeManagementFirestoreService {
  final FirebaseFirestore _firestore;
  final String _userId;

  TimeManagementFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userId = auth?.currentUser?.uid ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  CollectionReference<Map<String, dynamic>> get _tasksCollection =>
      _firestore.collection('users').doc(_userId).collection('timeManagementTasks');

  Future<void> addTask(TimeManagementTask task) async {
  try {
    await _tasksCollection.doc(task.id).set({
      ...task.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(), // 🔥 Add this line
    });
  } on FirebaseException catch (e) {
    throw TimeManagementException('Failed to add task: ${e.message}');
  }
}


  // Future<void> addTask(TimeManagementTask task) async {
  //   try {
  //     await _tasksCollection.doc(task.id).set(task.toMap());
  //   } on FirebaseException catch (e) {
  //     throw TimeManagementException('Failed to add task: ${e.message}');
  //   }
  // }

  Future<void> updateTask(TimeManagementTask task) async {
    try {
      await _tasksCollection.doc(task.id).update(task.toMap());
    } on FirebaseException catch (e) {
      throw TimeManagementException('Failed to update task: ${e.message}');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } on FirebaseException catch (e) {
      throw TimeManagementException('Failed to delete task: ${e.message}');
    }
  }

  Stream<List<TimeManagementTask>> getTasksStream() {
  print('TimeManagementFirestoreService initialized with UID: $_userId');
    return _tasksCollection.snapshots().handleError((error) {
      throw TimeManagementException('Failed to load tasks: $error');
    }).map((snapshot) => snapshot.docs
        .map((doc) => TimeManagementTask.fromMap(doc.data()))
        .toList());
  }

  Stream<List<TimeManagementTask>> getFilteredTasksStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> query = _tasksCollection;

    if (startDate != null && endDate != null) {
      query = query.where(
        'time',
        isGreaterThanOrEqualTo: _formatDateForQuery(startDate),
        isLessThanOrEqualTo: _formatDateForQuery(endDate),
      );
    }

    return query.snapshots().handleError((error) {
      throw TimeManagementException('Failed to load filtered tasks: $error');
    }).map((snapshot) => snapshot.docs
        .map((doc) => TimeManagementTask.fromMap(doc.data()))
        .toList());
  }

  Future<void> addTimeSpent(String taskId, double minutes) async {
    if (minutes <= 0) {
      throw TimeManagementException('Time spent must be greater than zero');
    }

    try {
      await _tasksCollection.doc(taskId).update({
        'timeSpent': FieldValue.arrayUnion([minutes]),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TimeManagementException('Failed to add time spent: ${e.message}');
    }
  }

  Stream<List<TimeAllocationData>> getTimeAllocationData() {
    return _tasksCollection
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .handleError((error) {
      throw TimeManagementException('Failed to load time allocation data: $error');
    }).map((snapshot) => snapshot.docs.map((doc) {
          final task = TimeManagementTask.fromMap(doc.data());
          return TimeAllocationData(
            taskId: task.id,
            taskTitle: task.title,
            timeSpent: task.totalTimeSpent,
          );
        }).toList());
  }

  String _formatDateForQuery(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.year}';
  }
}

class TimeManagementException implements Exception {
  final String message;
  TimeManagementException(this.message);

  @override
  String toString() => 'TimeManagementException: $message';
}