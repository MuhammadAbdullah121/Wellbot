// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_timezone/flutter_timezone.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tz;
// import 'package:wellbotapp/model/diet_fitness_model.dart';

// class ReminderService {
//   static final FlutterLocalNotificationsPlugin _notifications = 
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     tz.initializeTimeZones();
//     final String timeZoneName = await FlutterTimezone.getLocalTimezone();
//     tz.setLocalLocation(tz.getLocation(timeZoneName));

//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('app_icon');

//     await _notifications.initialize(
//       const InitializationSettings(
//         android: initializationSettingsAndroid,
//       ),
//       onDidReceiveNotificationResponse: (_) {}, // Add notification tap handler if needed
//     );

//     // Create notification channels once during initialization
//     await _createNotificationChannels();
//   }

//   Future<void> _createNotificationChannels() async {
//     const AndroidNotificationChannel mealChannel = AndroidNotificationChannel(
//       'meal_reminders',
//       'Meal Reminders',
//       description: 'Reminders for your scheduled meals',
//       importance: Importance.high,
//       sound: RawResourceAndroidNotificationSound('slow_spring_board'),
//     );

//     const AndroidNotificationChannel workoutChannel = AndroidNotificationChannel(
//       'workout_reminders',
//       'Workout Reminders',
//       description: 'Reminders for your scheduled workouts',
//       importance: Importance.high,
//       sound: RawResourceAndroidNotificationSound('slow_spring_board'),
//     );

//     await _notifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(mealChannel);

//     await _notifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(workoutChannel);
//   }

//   Future<void> scheduleDailyReminders(DietPlan dietPlan, FitnessPlan fitnessPlan) async {
//     try {
//       // Clear existing reminders before scheduling new ones
//       await cancelAllReminders();

//       // Schedule meal reminders with unique IDs
//       for (var entry in dietPlan.dailyMeals.entries) {
//         for (var (index, meal) in entry.value.indexed) {
//           await _scheduleMealReminder(meal, entry.key, index);
//         }
//       }

//       // Schedule workout reminders with unique IDs
//       for (var (index, workoutDay) in fitnessPlan.weeklySchedule.indexed) {
//         await _scheduleWorkoutReminder(workoutDay, index);
//       }
//     } catch (e) {
//       throw Exception('Failed to schedule reminders: $e');
//     }
//   }

//   Future<void> cancelAllReminders() async {
//     await _notifications.cancelAll();
//   }

//   Future<void> _scheduleMealReminder(Meal meal, String day, int index) async {
//     try {
//       final time = _parseTime(meal.time);
//       final notificationId = _generateUniqueId(day, index);

//       await _notifications.zonedSchedule(
//         notificationId,
//         'Meal Time!',
//         'Time for your ${meal.name}',
//         _nextInstanceOfTime(time),
//         const NotificationDetails(
//           android: AndroidNotificationDetails(
//             'meal_reminders',
//             'Meal Reminders',
//             channelDescription: 'Reminders for your scheduled meals',
//             importance: Importance.high,
//             priority: Priority.high,
//           ),
//         ),
//         payload: 'meal|${meal.name}|${meal.time}', // Add payload for handling
//         matchDateTime