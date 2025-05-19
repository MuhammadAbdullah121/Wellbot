import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:intl/intl.dart';

class TimeAllocationChart extends StatefulWidget {
  final Map<String, List<Map<String, dynamic>>> taskTimeSpent;
  final List<Map<String, dynamic>> tasks;

  const TimeAllocationChart({
    Key? key,
    required this.taskTimeSpent,
    required this.tasks,
  }) : super(key: key);

  @override
  _TimeAllocationChartState createState() => _TimeAllocationChartState();
}

class _TimeAllocationChartState extends State<TimeAllocationChart> {
  int _isDateView = 0;
  final List<Color> _chartColors = [
    Colors.blueAccent,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.deepOrange,
  ];

  List<ChartData> _generateChartDataForPeriod() {
    DateTime now = DateTime.now();
    Map<String, double> taskHours = {};

    widget.taskTimeSpent.forEach((taskId, entries) {
      String taskTitle = widget.tasks.firstWhere(
        (task) => task["id"] == taskId,
        orElse: () => {"title": "Unknown Task"},
      )["title"];

      double totalHours = 0.0;

      for (var entry in entries) {
        DateTime entryDate = DateFormat('dd-MM-yyyy').parse(entry["date"]);

        switch (_isDateView) {
          case 0: // All
            totalHours += entry["hoursSpent"];
            break;
          case 1: // Today
            if (entryDate.year == now.year &&
                entryDate.month == now.month &&
                entryDate.day == now.day) {
              totalHours += entry["hoursSpent"];
            }
            break;
          case 2: // 3 Days
            if (entryDate.isAfter(now.subtract(Duration(days: 3)))) {
              totalHours += entry["hoursSpent"];
            }
            break;
          case 3: // Week
            if (entryDate.isAfter(now.subtract(Duration(days: 7)))) {
              totalHours += entry["hoursSpent"];
            }
            break;
          case 4: // Month
            if (entryDate.year == now.year && entryDate.month == now.month) {
              totalHours += entry["hoursSpent"];
            }
            break;
        }
      }

      if (totalHours > 0) {
        taskHours[taskTitle] = totalHours;
      }
    });

    return taskHours.entries
        .map((entry) => ChartData(entry.key, entry.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _generateChartDataForPeriod();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: EdgeInsets.all(8),
      child: Container(
        height: 350, // Fixed height container
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ToggleSwitch(
                initialLabelIndex: _isDateView,
                totalSwitches: 5,
                labels: ['All', 'Today', '3D', 'Week', 'Month'],
                activeBgColors: [
                  [Colors.blue[800]!],
                  [Colors.blue[800]!],
                  [Colors.blue[800]!],
                  [Colors.blue[800]!],
                  [Colors.blue[800]!],
                ],
                inactiveBgColor: Colors.grey[200],
                activeFgColor: Colors.white,
                inactiveFgColor: Colors.blueGrey,
                onToggle: (index) {
                  setState(() {
                    _isDateView = index!;
                  });
                },
                minWidth: 60.0,
                customTextStyles: [
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ],
              ),
            ),
            Container(
              height: 250, // Fixed chart height
              padding: EdgeInsets.all(8),
              child: SfCircularChart(
                title: ChartTitle(
                  text: 'Task Time Allocation',
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[800],
                  ),
                ),
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                  textStyle: TextStyle(fontSize: 12),
                ),
                palette: _chartColors,
                series: <CircularSeries>[
                  DoughnutSeries<ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (ChartData data, _) => data.taskTitle,
                    yValueMapper: (ChartData data, _) => data.hoursSpent,
                    dataLabelMapper: (ChartData data, _) =>
                        '${data.hoursSpent.toStringAsFixed(1)}h',
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      connectorLineSettings: ConnectorLineSettings(
                        type: ConnectorType.curve,
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),
                    radius: '75%',
                    innerRadius: '60%',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  final String taskTitle;
  final double hoursSpent; // Renamed for clarity

  ChartData(this.taskTitle, this.hoursSpent);
}