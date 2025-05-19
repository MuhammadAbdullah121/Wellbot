import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class TimeManagementTask {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> tags;
  final List<double> timeSpent;

  TimeManagementTask({
    String? id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.tags,
    List<double>? timeSpent,
  })  : id = id ?? const Uuid().v4(),
        timeSpent = timeSpent ?? [];

  factory TimeManagementTask.fromMap(Map<String, dynamic> map) {
    try {
      final dateParts = map['time'].toString().split(' - ');
      final startDate = DateFormat('dd-MM-yyyy').parse(dateParts[0]);
      final endDate = dateParts.length > 1
          ? DateFormat('dd-MM-yyyy').parse(dateParts[1])
          : startDate.add(const Duration(days: 1));

      return TimeManagementTask(
        id: map['id'] as String? ?? '',
        title: map['title'] as String,
        startDate: startDate,
        endDate: endDate,
        tags: List<String>.from(map['tags'] as List<dynamic>? ?? []),
        timeSpent: List<double>.from(
          (map['timeSpent'] as List<dynamic>?)?.map((t) => t.toDouble()) ?? [],
        ),
      );
    } catch (e) {
      throw const FormatException('Invalid task data format');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'time': '${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)}',
      'tags': tags,
      'timeSpent': timeSpent,
    };
  }

  TimeManagementTask copyWith({
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    List<double>? timeSpent,
  }) {
    return TimeManagementTask(
      id: id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      timeSpent: timeSpent ?? this.timeSpent,
    );
  }

  void addTimeSpent(double minutes) {
    if (minutes > 0) {
      timeSpent.add(minutes);
    }
  }

  double get totalTimeSpent => timeSpent.fold(0.0, (sum, time) => sum + time);

  String get formattedTimeSpent {
    final totalMinutes = totalTimeSpent;
    final hours = (totalMinutes / 60).floor();
    final minutes = (totalMinutes % 60).round();

    final hoursText = hours > 0 
        ? '$hours ${hours == 1 ? 'hour' : 'hours'}'
        : '';
    final minutesText = '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';

    return hours > 0 ? '$hoursText $minutesText' : minutesText;
  }

  Duration get duration => endDate.difference(startDate);
}

class TimeAllocationData {
  final String taskId;
  final String taskTitle;
  final double timeSpent;

  const TimeAllocationData({
    required this.taskId,
    required this.taskTitle,
    required this.timeSpent,
  });
}