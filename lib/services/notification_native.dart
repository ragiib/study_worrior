// ============================================================================
// Notification Native Implementation
// ============================================================================

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _notifications.initialize(initSettings);
}

Future<void> showNotification({
  required String title,
  required String body,
  int id = 0,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'study_warrior_timer',
    'Timer Notifications',
    channelDescription: 'Notifications for Pomodoro timer events',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const details = NotificationDetails(android: androidDetails);
  await _notifications.show(id, title, body, details);
}

Future<void> cancelNotification(int id) async {
  await _notifications.cancel(id);
}

Future<void> cancelAll() async {
  await _notifications.cancelAll();
}
