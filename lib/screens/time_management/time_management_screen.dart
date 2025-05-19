import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wellbotapp/components/bottom_navigation_bar.dart';
import 'package:wellbotapp/components/background.dart';
import 'package:wellbotapp/firebase_CRUD/time_management_service.dart';
import 'package:wellbotapp/responsive.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/rendering.dart';

class TimeManagementScreen extends StatefulWidget {
  @override
  _TimeManagementScreenState createState() => _TimeManagementScreenState();
}

class _TimeManagementScreenState extends State<TimeManagementScreen>
    with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;
  int _isTaskScheduling = 0;
  int _isDateView = 0;
  DateTime _selectedDate = DateTime.now();
  late final List<DateTime> _dateList;
  final List<Map<String, dynamic>> _tasks = [];
  final Map<String, List<Map<String, dynamic>>> _taskTimeSpent = {};
  final Map<String, bool> _taskCompletionStatus = {};
  final Map<String, Map<String, dynamic>> _progressCache = {};
  List<Map<String, dynamic>> _filteredTasks = [];
  final TimeManagementService _service = TimeManagementService();

  @override
  void initState() {
    super.initState();
    _dateList =
        List.generate(90, (index) => DateTime.now().add(Duration(days: index)));
    _filteredTasks = List.from(_tasks);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tasks = await _service.getTasks();
      final timeSpent = await _service.getTimeSpent();
      final completionStatus = await _service.getCompletionStatus();

      setState(() {
        _tasks.clear();
        _tasks.addAll(tasks);
        _taskTimeSpent.clear();
        _taskTimeSpent.addAll(timeSpent);
        _taskCompletionStatus.clear();
        _taskCompletionStatus.addAll(completionStatus);
        _filteredTasks = List.from(_tasks);
      });
    } catch (e) {
      print('Error loading data: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      await _service.saveTasks(_tasks);
      await _service.saveTimeSpent(_taskTimeSpent);
      await _service.saveCompletionStatus(_taskCompletionStatus);
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  // Function to add task data
  void addTaskData(String taskTitle, double daySpent) {
    // Ensure the task exists in the map
    if (!_taskTimeSpent.containsKey(taskTitle)) {
      _taskTimeSpent[taskTitle] = [];
    }
    // Add the daySpent to the list (as a map with day and date info)
    _taskTimeSpent[taskTitle]
        ?.add({"day": "Unknown Day", "date": "Unknown Date"});
  }

  // Function to generate chart data
  List<ChartData> generateChartData() {
    List<ChartData> chartData = [];
    _taskTimeSpent.forEach((taskTitle, daysSpentList) {
      // Calculate total days spent for each task
      double totalDays = daysSpentList.length.toDouble();
      chartData.add(ChartData(taskTitle, totalDays));
    });
    return chartData;
  }

  // Debugging function to print the taskDaysSpent map
  void debugTaskDaysSpent() {
    _taskTimeSpent.forEach((taskTitle, daysSpentList) {
      print('Task: $taskTitle, Days Spent: $daysSpentList');
    });
  }

  // Function to save day spent
  void _saveDaySpent(int index, String dayName, String date) {
    final task = _tasks[index];
    String taskId = task["id"] ?? ""; // Default to empty string if null

    if (taskId.isNotEmpty) {
      // If the taskId doesn't exist, initialize it as an empty list
      if (_taskTimeSpent[taskId] == null) {
        _taskTimeSpent[taskId] = [];
      }

      // Add the day and date to the list for the given taskId
      _taskTimeSpent[taskId]?.add({"day": dayName, "date": date});

      // Call setState to update the UI
      setState(() {});
    } else {
      // Handle invalid or missing taskId (optional)
      print("Invalid task ID, time not saved.");
    }
  }

  void _filterTasks() {
    DateTime now = DateTime.now();

    _filteredTasks.clear();

    for (var task in _tasks) {
      DateTime taskStartDate =
          DateFormat('dd-MM-yyyy').parse(task["time"].split(' - ')[0]);

      switch (_isDateView) {
        case 0: // All
          _filteredTasks.add(task); // Simply add all tasks
          break;
        case 1: // Today
          if (taskStartDate.isBefore(now) ||
              taskStartDate.isAtSameMomentAs(now)) {
            _filteredTasks.add(task);
          }
          break;

        case 2: // Week
          DateTime startOfWeek = now.subtract(
              Duration(days: now.weekday - 1)); // Start of current week
          DateTime endOfWeek =
              startOfWeek.add(Duration(days: 6)); // End of current week

          // Check if taskStartDate is within the current week
          if (taskStartDate
                  .isAfter(startOfWeek.subtract(Duration(seconds: 1))) &&
              taskStartDate.isBefore(endOfWeek.add(Duration(seconds: 1)))) {
            _filteredTasks.add(task);
          }
          break;

        case 3: // Month
          DateTime firstDayOfCurrentMonth = DateTime(
              now.year, now.month, 1); // First day of the current month
          DateTime firstDayOfNextMonth = DateTime(
              now.year, now.month + 1, 1); // First day of the next month

          // Check if taskStartDate is within the current month
          if (taskStartDate.isAfter(
                  firstDayOfCurrentMonth.subtract(Duration(seconds: 1))) &&
              taskStartDate.isBefore(firstDayOfNextMonth)) {
            _filteredTasks.add(task);
          }
          break;

        default:
          break;
      }
    }

    setState(() {}); // Refresh UI after filtering
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _deleteTask(int index) async {
    final task = _tasks[index];
    String taskId = task["id"] ?? "";

    setState(() {
      // Remove from tasks list
      _tasks.removeAt(index);

      // Remove from filtered tasks list
      _filteredTasks.removeWhere((t) => t["id"] == taskId);

      // Remove from time spent data
      _taskTimeSpent.remove(taskId);

      // Remove from completion status
      _taskCompletionStatus.remove(taskId);

      // Clear progress cache
      _progressCache.clear();
    });

    await _saveData();
  }

  void _editTask(int index) async {
    final task = _tasks[index];
    final TextEditingController taskNameController =
        TextEditingController(text: task["title"]);
    final TextEditingController startDateController =
        TextEditingController(text: task["time"].split(' - ')[0]);
    final TextEditingController endDateController =
        TextEditingController(text: task["time"].split(' - ')[1]);
    String? selectedTaskType = task["tags"].isNotEmpty ? task["tags"][0] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Task',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: taskNameController,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        startDateController.text =
                            DateFormat('dd-MM-yyyy').format(pickedDate);
                      });
                    }
                  },
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        endDateController.text =
                            DateFormat('dd-MM-yyyy').format(pickedDate);
                      });
                    }
                  },
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Tech', 'Finance', 'Lifestyle', 'Other']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTaskType = value;
                    });
                  },
                  value: selectedTaskType,
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (taskNameController.text.isNotEmpty &&
                        startDateController.text.isNotEmpty &&
                        endDateController.text.isNotEmpty &&
                        selectedTaskType != null) {
                      setState(() {
                        _tasks[index] = {
                          "title": taskNameController.text,
                          "time":
                              "${startDateController.text} - ${endDateController.text}",
                          "tags": [selectedTaskType!],
                        };
                      });
                      Navigator.pop(context);
                      await _saveData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                        ),
                      );
                    }
                  },
                  child: Text('Update Task'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    textStyle:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTaskBottomSheet({DateTime? startDate, DateTime? endDate}) async {
    final TextEditingController taskNameController = TextEditingController();
    final TextEditingController startDateController = TextEditingController(
        text: startDate != null
            ? DateFormat('dd-MM-yyyy').format(startDate)
            : '');
    final TextEditingController endDateController = TextEditingController(
        text: endDate != null ? DateFormat('dd-MM-yyyy').format(endDate) : '');
    final List<String> taskTypes = ['Tech', 'Finance', 'Lifestyle', 'Other'];
    String? selectedTaskType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 20.0,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Task',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: taskNameController,
                  decoration: InputDecoration(
                    labelText: 'Task Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: startDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        startDateController.text =
                            DateFormat('dd-MM-yyyy').format(pickedDate);
                      });
                    }
                  },
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          endDate ?? DateTime.now().add(Duration(days: 1)),
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        endDateController.text =
                            DateFormat('dd-MM-yyyy').format(pickedDate);
                      });
                    }
                  },
                ),
                SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Task Type',
                    border: OutlineInputBorder(),
                  ),
                  items: taskTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTaskType = value;
                    });
                  },
                  value: selectedTaskType,
                ),
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: () async {
                    if (taskNameController.text.isNotEmpty &&
                        startDateController.text.isNotEmpty &&
                        endDateController.text.isNotEmpty &&
                        selectedTaskType != null) {
                      setState(() {
                        var uuid = Uuid();
                        String taskId = uuid.v4();

                        Map<String, dynamic> newTask = {
                          "id": taskId,
                          "title": taskNameController.text,
                          "time":
                              "${startDateController.text} - ${endDateController.text}",
                          "tags": [selectedTaskType ?? 'Other'],
                        };
                        _tasks.add(newTask);
                        _filteredTasks = List.from(_tasks);
                      });

                      Navigator.pop(context);
                      await _saveData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please fill all fields'),
                        ),
                      );
                    }
                  },
                  child: Text('Add Task'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                    textStyle:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          backgroundColor: Colors.blue,
          elevation: 0.0,
          centerTitle: true,
          title: Text(
            'Time Management',
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
          ),
        ),
      ),
      body: Background(
        child: Responsive(
          mobile: _buildFeatureContent(context),
          tablet: _buildFeatureContent(context),
          desktop: _buildFeatureContent(context, isDesktop: true),
        ),
      ),
      // floatingActionButton: ElevatedButton(
      //   onPressed: _showAddTaskBottomSheet,
      //   style: ElevatedButton.styleFrom(
      //     shape: CircleBorder(),
      //     backgroundColor: Colors.blue[800],
      //     padding: EdgeInsets.all(16),
      //     elevation: 8.0,
      //   ),
      //   child: Icon(Icons.mic, color: Colors.white, size: 22.0),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildFeatureContent(BuildContext context, {bool isDesktop = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 50.0 : 16.0,
        vertical: isDesktop ? 20.0 : 10.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleSwitch(), // Always show the toggle switch
          SizedBox(height: 20),
          if (_isTaskScheduling == 0) ...[
            _buildDateSelector(), // Show Date Selector
            SizedBox(height: 20),
            _buildToggleSwitchForDateView(), // Show Date View toggle switch
            SizedBox(height: 20),
            Expanded(child: _buildTaskList()), // Show Task List
            SizedBox(height: 20),
          ] else if (_isTaskScheduling == 1) ...[
            // Show Time Allocation with Task List and Chart
            Expanded(child: _buildTaskListForTimeAllocation()),
            SizedBox(height: 20),
            _buildTimeAllocationChart(),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeAllocationChart() {
    final chartData = _generateChartDataForPeriod();

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ToggleSwitch(
              initialLabelIndex: _isDateView,
              totalSwitches: 5,
              labels: ['All', 'Today', '3 Days', 'Week', 'Month'],
              activeBgColors: [
                [Colors.white],
                [Colors.white],
                [Colors.white],
                [Colors.white],
                [Colors.white],
              ],
              inactiveBgColor: Colors.blueGrey,
              activeFgColor: Colors.black,
              inactiveFgColor: Colors.white,
              onToggle: (index) {
                setState(() {
                  _isDateView = index!;
                });
              },
              minWidth: 60.0,
              customTextStyles: [
                TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
                TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
              ],
            ),
          ),
          Expanded(
            child: SfCircularChart(
              backgroundColor: Colors.white,
              title: ChartTitle(
                text: 'Hours Allocation Per Task',
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              legend: Legend(
                isVisible: true,
                overflowMode: LegendItemOverflowMode.wrap,
              ),
              series: <CircularSeries>[
                DoughnutSeries<ChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.taskTitle,
                  yValueMapper: (ChartData data, _) => data.DaysSpent,
                  dataLabelMapper: (ChartData data, _) =>
                      '${data.DaysSpent.toStringAsFixed(1)} hrs',
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  radius: '80%',
                  innerRadius: '60%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ChartData> _generateChartDataForPeriod() {
    DateTime now = DateTime.now();
    Map<String, double> taskHours = {};

    _taskTimeSpent.forEach((taskId, entries) {
      String taskTitle = _tasks.firstWhere(
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

  // Optimize task progress calculation with caching
  Map<String, dynamic> _calculateTaskProgress(String taskId) {
    if (_progressCache.containsKey(taskId)) {
      return _progressCache[taskId]!;
    }

    final task = _tasks.firstWhere((t) => t["id"] == taskId);
    final timeEntries = _taskTimeSpent[taskId] ?? [];
    final totalHoursSpent =
        timeEntries.fold(0.0, (sum, entry) => sum + entry["hoursSpent"]);

    final endDate =
        DateFormat('dd-MM-yyyy').parse(task["time"].split(' - ')[1]);
    final isOverdue = DateTime.now().isAfter(endDate) &&
        !(_taskCompletionStatus[taskId] ?? false);

    final progress = {
      "totalHoursSpent": totalHoursSpent,
      "isOverdue": isOverdue,
      "isCompleted": _taskCompletionStatus[taskId] ?? false,
    };

    _progressCache[taskId] = progress;
    return progress;
  }

  // Clear cache when task status changes
  void _clearProgressCache() {
    _progressCache.clear();
  }

  // Optimize task list building with const widgets
  Widget _buildTaskListForTimeAllocation() {
    return Container(
      height: 250,
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          String taskId = task["id"] ?? "";
          final progress = _calculateTaskProgress(taskId);

          return _buildTaskCardForTimeAllocation(task, progress, index);
        },
      ),
    );
  }

  // Separate widget for task card to improve rebuild performance
  Widget _buildTaskCardForTimeAllocation(
      Map<String, dynamic> task, Map<String, dynamic> progress, int index) {
    final bool isCompleted = progress["isCompleted"] ?? false;

    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          radius: 20,
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.task,
            color: isCompleted ? Colors.green : Colors.blue,
            size: 24,
          ),
        ),
        title: Text(
          task["title"] ?? "No Title",
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: progress["isOverdue"] ? Colors.red : Colors.black,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Hours: ${progress["totalHoursSpent"].toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[700],
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            if (progress["isOverdue"])
              Text(
                'Overdue!',
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isCompleted ? Icons.check_box : Icons.check_box_outline_blank,
                color: isCompleted ? Colors.green : Colors.grey,
              ),
              onPressed: () {
                setState(() {
                  _taskCompletionStatus[task["id"]] = !isCompleted;
                  _clearProgressCache();
                });
                _saveData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.green),
              onPressed: () => _editTask(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTask(index),
            ),
          ],
        ),
        onTap: isCompleted ? null : () => _openTimeSpentDialog(context, index),
      ),
    );
  }

  void _openTimeSpentDialog(BuildContext context, int index) {
    final task = _tasks[index];
    String taskId = task["id"] ?? "";
    final progress = _calculateTaskProgress(taskId);

    // Don't allow time entry for completed tasks
    if (progress["isCompleted"] ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add time to completed tasks'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get current date and time
    DateTime now = DateTime.now();
    String todayDate = DateFormat('dd-MM-yyyy').format(now);
    String todayDay = DateFormat('EEEE').format(now);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController dateController =
            TextEditingController(text: todayDate);
        TextEditingController dayController =
            TextEditingController(text: todayDay);
        TextEditingController hoursController = TextEditingController();
        DateTime? selectedDate = now;

        return AlertDialog(
          title: Text('Enter Time Spent for ${task["title"]}'),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: 'Tap to select a date',
                    suffixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    selectedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? now,
                      firstDate: DateTime(now.year - 5),
                      lastDate: DateTime(now.year + 5),
                    );
                    if (selectedDate != null) {
                      String formattedDate =
                          DateFormat('dd-MM-yyyy').format(selectedDate!);
                      dateController.text = formattedDate;
                      dayController.text =
                          DateFormat('EEEE').format(selectedDate!);
                    }
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: dayController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Day',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: hoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Hours Spent',
                    border: OutlineInputBorder(),
                    suffixText: 'hours',
                    hintText: 'Enter hours spent today',
                  ),
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (hoursController.text.isNotEmpty) {
                  _saveTimeSpent(
                    index,
                    dayController.text,
                    dateController.text,
                    hoursController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter hours spent')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToggleSwitch() {
    return Center(
      child: ToggleSwitch(
        initialLabelIndex: _isTaskScheduling,
        totalSwitches: 2,
        labels: ['Task Scheduling', 'Time Allocation'],
        activeBgColors: [
          [Colors.white],
          [Colors.white],
        ],
        inactiveBgColor: Colors.blueGrey,
        activeFgColor: Colors.black,
        inactiveFgColor: Colors.white,
        onToggle: (index) {
          setState(() {
            _isTaskScheduling = index!;
          });
        },
        minWidth: 200.0,
        customTextStyles: [
          TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
          TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
        ],
      ),
    );
  }

  Widget _buildToggleSwitchForDateView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        ToggleSwitch(
          initialLabelIndex: _isDateView,
          totalSwitches: 4,
          labels: ['All', 'Today', 'Week', 'Month'],
          activeBgColors: [
            [Colors.white],
            [Colors.white],
            [Colors.white],
            [Colors.white],
          ],
          inactiveBgColor: Colors.blueGrey,
          activeFgColor: Colors.black,
          inactiveFgColor: Colors.white,
          onToggle: (index) {
            setState(() {
              _isDateView = index!; // Update the selected view
            });
            _filterTasks(); // Apply the filtering logic
          },
          minWidth: 60.0,
          customTextStyles: [
            TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
            TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
            TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
            TextStyle(fontWeight: FontWeight.bold, fontSize: 12.0),
          ],
        ),
        SizedBox(width: 20),
        Flexible(
          child: ElevatedButton(
            onPressed: _showAddTaskBottomSheet,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.lightBlue,
              side: BorderSide(color: Colors.lightBlue, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            ),
            child: Text(
              'Add Task',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    ScrollController _scrollController = ScrollController();

    void _scrollLeft() {
      _scrollController.animateTo(
        _scrollController.offset - 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    void _scrollRight() {
      _scrollController.animateTo(
        _scrollController.offset + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    return Container(
      height: 95,
      child: Row(
        children: [
          if (Responsive.isDesktop(context))
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _scrollLeft,
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _dateList.length,
              itemBuilder: (context, index) {
                DateTime date = _dateList[index];
                bool isSelected = date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;

                return GestureDetector(
                  onTap: () {
                    _selectDate(date);
                    _showAddTaskBottomSheet(
                      startDate: _selectedDate,
                      endDate: _selectedDate.add(const Duration(days: 1)),
                    );
                  },
                  child: Container(
                    width: 70,
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.grey[200] : Colors.blueGrey,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.grey[600] : Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('dd').format(date),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white,
                          ),
                        ),
                        Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.grey[600] : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (Responsive.isDesktop(context))
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _scrollRight,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      itemCount: _filteredTasks.length, // Use the filtered list here
      itemBuilder: (context, index) {
        final task = _filteredTasks[index]; // Use filtered tasks
        return _buildTaskCard(
          task["title"],
          task["time"],
          task["tags"],
          index,
        );
      },
    );
  }

  Widget _buildTaskCard(
      String title, String time, List<dynamic> tags, int index) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding: EdgeInsets.all(8.0),
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          radius: 25,
          child: Icon(Icons.task, color: Colors.blue, size: 30),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Wrap(
              spacing: 6.0,
              children: tags
                  .where((tag) => tag != null) // Ensure no null values are used
                  .map((tag) => Chip(
                        label: Text(
                          tag.toString(),
                          style: TextStyle(fontSize: 12.0, color: Colors.white),
                        ),
                        backgroundColor: tag.toString() == "Tech"
                            ? Colors.blue
                            : tag.toString() == "Finance"
                                ? Colors.green
                                : tag.toString() == "Lifestyle"
                                    ? Colors.purple
                                    : Colors.orange,
                      ))
                  .toList(),
            ),
          ],
        ),
        subtitle: Text(
          time,
          style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
        ),
        trailing: Wrap(
          spacing: 6.0,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.green),
              onPressed: () => _editTask(index),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTask(index),
            ),
          ],
        ),
      ),
    );
  }

  // Update the task data structure
  void _saveTimeSpent(
      int index, String dayName, String date, String hoursSpent) {
    final task = _tasks[index];
    String taskId = task["id"] ?? "";

    if (taskId.isNotEmpty) {
      if (_taskTimeSpent[taskId] == null) {
        _taskTimeSpent[taskId] = [];
      }

      _taskTimeSpent[taskId]?.add({
        "day": dayName,
        "date": date,
        "hoursSpent": double.parse(hoursSpent),
      });

      setState(() {});
      _saveData();
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class ChartData {
  final String taskTitle;
  final double
      DaysSpent; // DaysSpent should be a double to represent numerical data

  ChartData(this.taskTitle, this.DaysSpent);
}
