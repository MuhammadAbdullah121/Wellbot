import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/screens/time_management/time_allocation_chart.dart';
import 'package:wellbotapp/firebase_CRUD/time_management_service.dart';

class StatisticsScreen extends StatefulWidget {
  final FirebaseFirestore? firestore;
  final FirebaseAuth? auth;

  const StatisticsScreen({super.key, this.firestore, this.auth});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}


class _StatisticsScreenState extends State<StatisticsScreen> {
  List<ChartData> caloriesData = [];
  List<ChartData> waterData = [];
  List<ChartData> sleepData = [];
  List<ChartData> exerciseData = [];
  List<ChartData> expenseVsIncome = [];
  List<ChartData> goalProgress = [];
  List<ChartData> timeSpentData = [];
  List<ChartData> socialProgress = [];
  bool _isLoading = true;
  int _currentIndex = 1;
  final Map<String, List<Map<String, dynamic>>> _taskTimeSpent = {};
  final List<Map<String, dynamic>> _tasks = [];
  final TimeManagementService _timeManagementService = TimeManagementService();

  @override
  void initState() {
    super.initState();
    fetchAllData();
    _fetchTimeManagementData();
  }

  Future<void> fetchAllData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    await Future.wait([
      fetchDailyTracking(userId),
      fetchExpensesAndIncome(userId),
      fetchGoals(userId),
      _fetchTimeManagementData(),
      fetchSocialProgress(userId),
    ]);
    setState(() => _isLoading = false);
  }

   Future<void> fetchSocialProgress(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('social_progress')
        .where('userId', isEqualTo: userId)
        .orderBy('lastUpdated')
        .get();

    socialProgress = [];
    for (var doc in snapshot.docs) {
      final date = _formatDate(doc['lastUpdated'].toDate());
      final progress = ((doc['affirmationCompleted'] ? 1 : 0) +
              (doc['smallTalkCompleted'] ? 1 : 0)) *
          50;
      socialProgress.add(ChartData(date, progress.toDouble()));
    }
  }


  Future<void> fetchDailyTracking(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('daily_tracking')
          .where('userId', isEqualTo: userId)
          .orderBy('date')
          .get();

      caloriesData = [];
      waterData = [];
      sleepData = [];
      exerciseData = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = _formatDate(data['date'].toDate());
        final calories = (data['calories'] ?? 0).toDouble();
        final water = (data['water'] ?? 0).toDouble();
        final sleep = (data['hoursSlept'] ?? 0).toDouble();
        final exercises = List<bool>.from(data['exercises'] ?? []);

        caloriesData.add(ChartData(date, calories));
        waterData.add(ChartData(date, water));
        sleepData.add(ChartData(date, sleep));
        exerciseData.add(ChartData(date, exercises.where((e) => e).length.toDouble()));
      }
    } catch (e) {
      print('Error fetching daily tracking: $e');
    }
  }

  Future<void> fetchExpensesAndIncome(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: userId)
        .get();

    double totalIncome = 0;
    double totalExpenses = 0;

    for (var doc in snapshot.docs) {
      final amount = (doc['amount'] ?? 0).toDouble();
      if (doc['expenseIncome'] == false) {
        totalIncome += amount;
      } else {
        totalExpenses += amount;
      }
    }

    expenseVsIncome = [
      ChartData('Income', totalIncome, Colors.green),
      ChartData('Expenses', totalExpenses, Colors.red),
    ];
  }

  Future<void> fetchGoals(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('goals')
        .where('userId', isEqualTo: userId)
        .get();

    goalProgress = [];
    for (var doc in snapshot.docs) {
      final current = (doc['currentAmount'] ?? 0).toDouble();
      final target = (doc['finalAmount'] ?? 1).toDouble();
      goalProgress.add(ChartData(doc['title'], (current / target) * 100));
    }
  }

  Future<void> _fetchTimeManagementData() async {
    try {
      final tasks = await _timeManagementService.getTasks();
      final timeSpent = await _timeManagementService.getTimeSpent();
      setState(() {
        _tasks.clear();
        _tasks.addAll(tasks);
        _taskTimeSpent.clear();
        _taskTimeSpent.addAll(timeSpent);
      });
    } catch (e) {
      print('Error loading time management data: $e');
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Background(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Progress Statistics'),
          backgroundColor: Colors.blue,
          elevation: 4,
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Health Tracking'),
              _buildLineChart('Calorie Intake', caloriesData, 'Calories', Colors.amber),
              SizedBox(height: 20),
              _buildLineChart('Water Consumption', waterData, 'Glasses', Colors.blue),
              SizedBox(height: 20),
              _buildLineChart('Sleep Hours', sleepData, 'Hours', Colors.purple),
              SizedBox(height: 20),
              _buildLineChart('Exercises Completed', exerciseData, 'Count', Colors.green),
              
              _buildSectionTitle('Financial Overview'),
              _buildFinancialPieChart(),
              SizedBox(height: 20),
              
              _buildSectionTitle('Goal Progress'),
              _buildGoalProgressChart(),
              SizedBox(height: 20),
              
              _buildSectionTitle('Time Management'),
              TimeAllocationChart(taskTimeSpent: _taskTimeSpent, tasks: _tasks),
              SizedBox(height: 20),
              
              _buildSectionTitle('Social Activities'),
              _buildLineChart('Social Progress', socialProgress, 'Progress %', Colors.pink),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  Widget _buildLineChart(String title, List<ChartData> data, String yTitle, Color color) {
    if (data.isEmpty) return _buildEmptyState('No $title data available');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            Container(
              height: 250,
              child: SfCartesianChart(
                margin: EdgeInsets.all(10),
                primaryXAxis: CategoryAxis(
                  labelRotation: -45,
                  labelStyle: TextStyle(fontSize: 12),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: yTitle),
                  labelFormat: '{value}',
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <CartesianSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: data,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    color: color,
                    width: 3,
                    markerSettings: MarkerSettings(
                      isVisible: true,
                      shape: DataMarkerType.circle,
                      color: color,
                      borderWidth: 2,
                    ),
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelAlignment: ChartDataLabelAlignment.top,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialPieChart() {
    if (expenseVsIncome.isEmpty) return _buildEmptyState('No financial data available');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Income vs Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            Container(
              height: 300,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: TextStyle(fontSize: 14),
                ),
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    dataSource: expenseVsIncome,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    pointColorMapper: (ChartData data, _) => data.color,
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(fontSize: 12),
                      connectorLineSettings: ConnectorLineSettings(
                        length: '20%',
                        type: ConnectorType.curve,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(Colors.green, 'Income'),
                  _buildLegendItem(Colors.red, 'Expenses'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressChart() {
    if (goalProgress.isEmpty) return _buildEmptyState('No goal progress data available');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            Container(
              height: 250,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.right,
                  overflowMode: LegendItemOverflowMode.scroll,
                ),
                series: <CircularSeries>[
                  RadialBarSeries<ChartData, String>(
                    dataSource: goalProgress,
                    xValueMapper: (ChartData data, _) => data.label,
                    yValueMapper: (ChartData data, _) => data.value,
                    maximumValue: 100,
                    radius: '90%',
                    gap: '2%',
                    cornerStyle: CornerStyle.bothCurve,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final Color? color;

  ChartData(this.label, this.value, [this.color]);
}