import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellbotapp/screens/statistics_page.dart';

class TopWidgets extends StatefulWidget {
  @override
  _TopWidgetsState createState() => _TopWidgetsState();
}

class _TopWidgetsState extends State<TopWidgets> {
  double _balance = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('expenses')
          .where('userId', isEqualTo: user.uid)
          .get();

      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in snapshot.docs) {
        final amount = (doc['amount'] ?? 0).toDouble();
        if (doc['expenseIncome'] == false) { // Income
          totalIncome += amount;
        } else { // Expense
          totalExpense += amount;
        }
      }

      setState(() {
        _balance = totalIncome - totalExpense;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching balance: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 9.0),
        _buildStatisticsHeader(context),
        _buildBalanceWidget(context),
      ],
    );
  }

  Widget _buildStatisticsHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Statistics',
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: Colors.blue.shade900, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              offset: Offset(2.0, 2.0),
              blurRadius: 6.0,
              spreadRadius: 0.6,
            ),
          ],
        ),
        padding: EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash in Hand',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 6.0),
            Row(
              children: [
                Expanded(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'PKR ${_balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                ),
                SizedBox(width: 8.0),
                Image.asset('assets/images/Capture.PNG', 
                    height: 50.0, fit: BoxFit.contain),
              ],
            ),
            SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomLeft,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => StatisticsScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  elevation: 4.0,
                ),
                child: Text(
                  'View Detail',
                  style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}