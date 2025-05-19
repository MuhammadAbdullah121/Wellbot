import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'package:wellbotapp/model/money_manage.dart';
import 'package:wellbotapp/firebase_CRUD/money_services.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  _GoalSettingScreenState createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  double workDonePercentage = 0.0;
  FinancialGoalModel? currentGoal;
  final FirestoreService firestoreService = FirestoreService();
  Timer? _dailyTimer;
  bool _isLoading = false;
  List<FinancialGoalModel> _goals = []; // List to hold all fetched goals
  int _currentGoalIndex = 0; // Index to track the currently displayed goal

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _dailyTimer?.cancel();
    super.dispose();
  }

  // Fetch all goals from Firestore
  void _loadGoals() async {
    setState(() {
      _isLoading = true;
    });
    try {
      _goals = await firestoreService.fetchGoals(); // Fetch all goals
      if (_goals.isNotEmpty) {
        setState(() {
          currentGoal = _goals.first; // Initialize with the first goal
          _currentGoalIndex = 0;
          _updateWorkDonePercentage();
        });
      } else {
        setState(() {
          currentGoal = null;
        });
      }
    } catch (error) {
      print("Error fetching goals: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load goals: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateWorkDonePercentage() {
  if (currentGoal != null && currentGoal!.finalAmount > 0) {
    final totalProgress = currentGoal!.initialAmount + currentGoal!.currentAmount;
    workDonePercentage = (totalProgress / currentGoal!.finalAmount) * 100;
    workDonePercentage = workDonePercentage.clamp(0, 100);
  } else {
    workDonePercentage = 0;
  }
}

  void _showNextGoal() {
    if (_goals.isNotEmpty && _currentGoalIndex < _goals.length - 1) {
      setState(() {
        _currentGoalIndex++;
        currentGoal = _goals[_currentGoalIndex];
        _updateWorkDonePercentage();
      });
    }
  }

  void _showPreviousGoal() {
    if (_goals.isNotEmpty && _currentGoalIndex > 0) {
      setState(() {
        _currentGoalIndex--;
        currentGoal = _goals[_currentGoalIndex];
        _updateWorkDonePercentage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildActionButtons(),
                const SizedBox(height: 20),
                _buildGoalCard(),
                const SizedBox(height: 20),
                _buildDoughnutChart(),
              ],
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          // Sliding arrows
          if (_goals.isNotEmpty) ...[
            //spread operator
            Positioned(
              left: 10,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 50),
                onPressed: _showPreviousGoal,
              ),
            ),
            Positioned(
              right: 10,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 50),
                onPressed: _showNextGoal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildElevatedButton("Add Goal", _showAddGoalBottomSheet),
        ),
        Expanded(
          child:
              _buildElevatedButton("Add Progress", _showAddProgressBottomSheet),
        ),
        Expanded(
          child: _buildElevatedButton("Delete Goal", (_) => _deleteGoal()),
        ),
      ],
    );
  }

  ElevatedButton _buildElevatedButton(
      String text, Function(BuildContext) onPressed) {
    return ElevatedButton(
      onPressed: () => onPressed(context),
      child: Text(text),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(10, 5),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildDoughnutChart() {
    if (currentGoal == null) {
      return const Center(child: Text("No goal set yet."));
    }

    return SfCircularChart(
      series: <CircularSeries>[
        DoughnutSeries<ChartData, String>(
          dataSource: [
            ChartData('Work Done', workDonePercentage, Colors.green),
            ChartData('Remaining', 100 - workDonePercentage, Colors.red),
          ],
          pointColorMapper: (ChartData data, _) => data.color,
          xValueMapper: (ChartData data, _) => data.label,
          yValueMapper: (ChartData data, _) => data.value,
          innerRadius: '70%',
          dataLabelSettings: const DataLabelSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    if (currentGoal == null) {
      return const Center(child: Text("No goal available."));
    }
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentGoal!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Initial Amount: PKR ${currentGoal!.initialAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              "Final Amount: PKR ${currentGoal!.finalAmount.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              "Current Progress: PKR ${(currentGoal!.initialAmount + currentGoal!.currentAmount).toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final initialAmountController = TextEditingController();
    final finalAmountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _buildBottomSheetContent(
          [
            _buildTextField(titleController, 'Goal Title'),
            _buildTextField(initialAmountController, 'Initial Amount',
                TextInputType.numberWithOptions(decimal: true)),
            _buildTextField(finalAmountController, 'Final Amount',
                TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 10),
            _buildConfirmationButton(() async {
              if (_isGoalFormValid(
                titleController.text,
                initialAmountController.text,
                finalAmountController.text,
              )) {
                final newGoal = FinancialGoalModel(
                  id: '',
                  title: titleController.text,
                  initialAmount: double.parse(initialAmountController.text),
                  finalAmount: double.parse(finalAmountController.text),
                  currentAmount: 0.0,
                  userId: FirebaseAuth.instance.currentUser!.uid,
                );
                try {
                  await firestoreService.addGoal(newGoal);
                  _loadGoals();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal added successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add goal: $e'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please fill in all fields with valid numbers.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            }),
          ],
        );
      },
    );
  }

  void _showAddProgressBottomSheet(BuildContext context) {
    final progressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _buildBottomSheetContent(
          [
            _buildTextField(progressController, 'Progress Amount',
                TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 20),
            _buildConfirmationButton(() async {
              if (currentGoal != null) {
                final progressAmount = double.parse(progressController.text);

                if (progressAmount > 0) {
                  try {
                    await firestoreService.addProgress(
                        currentGoal!.id, progressAmount);
                    _loadGoals();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Progress added successfully!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add progress: $e'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a positive amount.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            }),
          ],
        );
      },
    );
  }

  void _deleteGoal() async {
    if (currentGoal != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Goal'),
          content: const Text('Are you sure you want to delete this goal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await firestoreService.deleteGoal(currentGoal!.id);
                  _loadGoals();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Goal deleted successfully!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete goal: $e'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No goal to delete.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildBottomSheetContent(List<Widget> children) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }

  TextField _buildTextField(TextEditingController controller, String label,
      [TextInputType? inputType]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: inputType,
    );
  }

  ElevatedButton _buildConfirmationButton(VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: const Text("Confirm Goal"),
    );
  }

  bool _isGoalFormValid(
      String title, String initialAmount, String finalAmount) {
    if (title.isEmpty || initialAmount.isEmpty || finalAmount.isEmpty) {
      return false;
    }
    final initial = double.tryParse(initialAmount);
    final finalAmountParsed = double.tryParse(finalAmount);

    if (initial == null ||
        finalAmountParsed == null ||
        initial < 0 ||
        finalAmountParsed <= 0 ||
        finalAmountParsed < initial) {
      return false;
    }
    return true;
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
