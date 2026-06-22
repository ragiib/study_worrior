// ============================================================================
// Notification Web Stub - No-op for web platform
// ============================================================================

Future<void> initNotifications() async {}

Future<void> showNotification({
  required String title,
  required String body,
  int id = 0,
}) async {}

Future<void> cancelNotification(int id) async {}

Future<void> cancelAll() async {}
