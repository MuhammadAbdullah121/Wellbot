import 'package:flutter/material.dart';

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void initializeNotifications() {
    _notifications = _generateAllScreenNotifications();
    _updateUnreadCount();
    notifyListeners();
  }

  void markAsRead(int index) {
    if (index < _notifications.length && !_notifications[index]['isRead']) {
      _notifications[index]['isRead'] = true;
      _updateUnreadCount();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var notification in _notifications) {
      notification['isRead'] = true;
    }
    _updateUnreadCount();
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n['isRead']).length;
  }

  List<Map<String, dynamic>> _generateAllScreenNotifications() {
    return [
      // Time Management notifications
      {
        'title': 'Task Reminder',
        'message': 'Don\'t forget to complete your daily workout routine!',
        'time': '2 hours ago',
        'type': 'reminder',
        'screen': 'Time Management',
        'isRead': false,
      },
      {
        'title': 'Time Allocation Update',
        'message': 'You\'ve spent 4 hours on work tasks today. Great progress!',
        'time': '4 hours ago',
        'type': 'update',
        'screen': 'Time Management',
        'isRead': false,
      },
      // Diet & Fitness notifications
      {
        'title': 'Meal Reminder',
        'message': 'Time for your healthy lunch! Don\'t skip meals.',
        'time': '6 hours ago',
        'type': 'reminder',
        'screen': 'Diet & Fitness',
        'isRead': true,
      },
      {
        'title': 'Fitness Achievement',
        'message': 'Congratulations! You\'ve reached your weekly exercise goal.',
        'time': '1 day ago',
        'type': 'achievement',
        'screen': 'Diet & Fitness',
        'isRead': false,
      },
      {
        'title': 'Calorie Alert',
        'message': 'You\'re 200 calories over your daily limit. Consider a light dinner.',
        'time': '1 day ago',
        'type': 'warning',
        'screen': 'Diet & Fitness',
        'isRead': true,
      },
      // Money Management notifications
      {
        'title': 'Budget Achievement',
        'message': 'Great job! You\'ve saved 20% more than planned this month.',
        'time': '2 days ago',
        'type': 'achievement',
        'screen': 'Money Management',
        'isRead': false,
      },
      {
        'title': 'Expense Alert',
        'message': 'You\'re approaching your entertainment budget limit for this month.',
        'time': '3 days ago',
        'type': 'warning',
        'screen': 'Money Management',
        'isRead': true,
      },
      {
        'title': 'Investment Update',
        'message': 'Your investment portfolio gained 2.5% this week.',
        'time': '3 days ago',
        'type': 'update',
        'screen': 'Money Management',
        'isRead': true,
      },
      // Social Helper notifications
      {
        'title': 'Social Connection',
        'message': 'It\'s been a while since you connected with friends. Plan a meetup!',
        'time': '4 days ago',
        'type': 'reminder',
        'screen': 'Social Helper',
        'isRead': true,
      },
      {
        'title': 'Event Reminder',
        'message': 'Community volunteering event tomorrow at 10 AM.',
        'time': '5 days ago',
        'type': 'reminder',
        'screen': 'Social Helper',
        'isRead': true,
      },
      {
        'title': 'Social Goal',
        'message': 'You\'ve attended 3 social events this month. Keep it up!',
        'time': '1 week ago',
        'type': 'achievement',
        'screen': 'Social Helper',
        'isRead': true,
      },
      // General app notifications
      {
        'title': 'App Update',
        'message': 'WellBot has been updated with new features and improvements.',
        'time': '1 week ago',
        'type': 'update',
        'screen': 'General',
        'isRead': true,
      },
      {
        'title': 'Weekly Summary',
        'message': 'Your overall wellness score improved by 15% this week!',
        'time': '1 week ago',
        'type': 'achievement',
        'screen': 'General',
        'isRead': true,
      },
    ];
  }
}