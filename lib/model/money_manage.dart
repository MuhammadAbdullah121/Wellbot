import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseTrackingModel {
  String id;
  String title;
  double amount;
  DateTime date;
  bool expenseIncome; // true for expense, false for income
  String userId;

  ExpenseTrackingModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.expenseIncome,
    required this.userId,
  });

  // Convert Firestore document to model
  factory ExpenseTrackingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseTrackingModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      expenseIncome: data['expenseIncome'] ?? true,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
  return {
    'title': title,
    'amount': amount,
    'date': Timestamp.fromDate(date),  // Ensure it's stored as a Firestore Timestamp
    'expenseIncome': expenseIncome,
    'userId': userId,
  };
}
}

//........................................................................

class FinancialGoalModel {
  final String id;
  final String title;
  final double initialAmount;
  final double finalAmount;
  double currentAmount;
  final String userId; // User ID for goal tracking

  FinancialGoalModel({
    required this.id,
    required this.title,
    required this.initialAmount,
    required this.finalAmount,
    required this.currentAmount,
    required this.userId,
  });

  // Create a FinancialGoalModel from Firestore Document
  factory FinancialGoalModel.fromFirestore(String id, Map<String, dynamic> data) {
    return FinancialGoalModel(
      id: id, // Document ID
      title: data['title'] ?? '',
      initialAmount: (data['initialAmount'] ?? 0).toDouble(),
      finalAmount: (data['finalAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      userId: data['userId'] ?? '', // Ensure userId is handled
    );
  }

  // Convert FinancialGoalModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'initialAmount': initialAmount,
      'finalAmount': finalAmount,
      'currentAmount': currentAmount,
      'userId': userId,
    };
  }
}
