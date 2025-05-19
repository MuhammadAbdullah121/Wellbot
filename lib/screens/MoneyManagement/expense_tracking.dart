import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellbotapp/model/money_manage.dart';

class ExpenseTrackingScreen extends StatefulWidget {
  const ExpenseTrackingScreen({super.key});

  @override
  _ExpenseTrackingScreenState createState() => _ExpenseTrackingScreenState();
}

class _ExpenseTrackingScreenState extends State<ExpenseTrackingScreen> {
  bool isExpense = true; // Default selection
  double totalIncome = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!authSnapshot.hasData || authSnapshot.data == null) {
            return const Center(
                child: Text("Please log in to see your expenses."));
          }

          String uid = authSnapshot.data!.uid;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('expenses')
                .where('userId', isEqualTo: uid)
                .orderBy('date', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "No data available. Add some expenses or income to get started!",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Calculate totals
              totalIncome = 0.0;
              totalExpense = 0.0;
              for (var doc in snapshot.data!.docs) {
                final data = ExpenseTrackingModel.fromFirestore(doc);
                if (data.expenseIncome) {
                  totalExpense += data.amount;
                } else {
                  totalIncome += data.amount;
                }
              }
              balance = totalIncome - totalExpense;

              return ListView(
                children: [
                  _buildSummaryCard(),
                  _buildExpenseList(snapshot.data!.docs),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDataBottomSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Balance: PKR ${balance.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Total Income: PKR ${totalIncome.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Total Expense: PKR ${totalExpense.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<QueryDocumentSnapshot> docs) {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: docs.length,
    itemBuilder: (context, index) {
      final doc = docs[index];
      final data = ExpenseTrackingModel.fromFirestore(doc);
      return Dismissible(
        key: Key(doc.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Delete Expense"),
              content: const Text("Are you sure you want to delete this item?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          try {
            await _firestore.collection('expenses').doc(doc.id).delete();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Item deleted successfully"),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error deleting item: $e"),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              data.expenseIncome
                  ? Icons.remove_circle_outline
                  : Icons.add_circle_outline,
              color: data.expenseIncome ? Colors.red : Colors.green,
            ),
            title: Text(
              data.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Date: ${data.date.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Text(
              'PKR ${data.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: data.expenseIncome ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    },
  );
}
  void _showAddDataBottomSheet() {
    TextEditingController titleController = TextEditingController();
    TextEditingController amountController = TextEditingController();
    List<bool> isSelected = [true, false];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ToggleButtons(
                      isSelected: isSelected,
                      onPressed: (index) {
                        setModalState(() {
                          isSelected = [index == 0, index == 1];
                          isExpense = index == 0;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      selectedColor: Colors.white,
                      color: Colors.black,
                      fillColor: isSelected[0] ? Colors.red : Colors.green,
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child:
                              Text('Expense', style: TextStyle(fontSize: 16)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Income', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title')),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            amountController.text.isNotEmpty) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final model = ExpenseTrackingModel(
                            title: titleController.text,
                            amount: double.parse(amountController.text),
                            date: DateTime.now(),
                            expenseIncome: isExpense,
                            userId: user.uid,
                            id: '',
                          );
                          await FirebaseFirestore.instance
                              .collection('expenses')
                              .add(model.toMap());
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
