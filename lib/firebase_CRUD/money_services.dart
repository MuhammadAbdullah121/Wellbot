import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellbotapp/model/money_manage.dart';

class ExpenseService {
  final CollectionReference _expenseCollection =
      FirebaseFirestore.instance.collection('expenses');

  // Add expense or income
  Future<void> addExpense(ExpenseTrackingModel expense) async {
    try {
      await _expenseCollection.add(expense.toMap());
    } catch (e) {
      throw Exception("Error adding expense: $e");
    }
  }

  // Delete expense
  Future<void> deleteExpense(String docId) async {
    try {
      await _expenseCollection.doc(docId).delete();
    } catch (e) {
      throw Exception("Error deleting expense: $e");
    }
  }

  // Fetch expenses in real-time
  Stream<List<ExpenseTrackingModel>> getExpenses() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    return _expenseCollection
        .where('userId', isEqualTo: uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExpenseTrackingModel.fromFirestore(doc)).toList());
  }
}

//.....................................................................


class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Add a new financial goal (only for authenticated users)
  Future<void> addGoal(FinancialGoalModel goal) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return;
      }

      await _db.collection('goals').add({
        ...goal.toMap(),
        'userId': user.uid, // Ensures goal is linked to the logged-in user
      });
    } catch (e) {
      print('Error adding goal: $e');
    }
  }

  // ✅ Fetch financial goals (only the goals of the logged-in user)
  Future<List<FinancialGoalModel>> fetchGoals() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return [];
      }

      final snapshot = await _db.collection('goals')
        .where('userId', isEqualTo: user.uid) // 🔥 Fetch only user's goals
        .get();

      return snapshot.docs.map((doc) {
        return FinancialGoalModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error fetching goals: $e');
      return [];
    }
  }

  // ✅ Delete a goal (only if the goal belongs to the logged-in user)
  Future<void> deleteGoal(String goalId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return;
      }

      await _db.collection('goals').doc(goalId).delete();
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  // ✅ Add progress to a goal (update current amount)
  Future<void> addProgress(String goalId, double progressAmount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return;
      }

      final goalDoc = await _db.collection('goals').doc(goalId).get();
      if (goalDoc.exists && goalDoc.data()?['userId'] == user.uid) {
        final currentAmount = goalDoc.data()?['currentAmount'] ?? 0.0;
        final newAmount = currentAmount + progressAmount;
        await _db.collection('goals').doc(goalId).update({
          'currentAmount': newAmount,
        });
      }
    } catch (e) {
      print('Error adding progress: $e');
    }
  }

  // ✅ Update a goal (only if it belongs to the logged-in user)
  Future<void> updateGoal(String goalId, Map<String, dynamic> updatedFields) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('User not authenticated');
        return;
      }

      final goalDoc = await _db.collection('goals').doc(goalId).get();
      if (goalDoc.exists && goalDoc.data()?['userId'] == user.uid) {
        await _db.collection('goals').doc(goalId).update(updatedFields);
      }
    } catch (e) {
      print('Error updating goal: $e');
    }
  }
}
