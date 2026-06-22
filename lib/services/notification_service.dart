// ============================================================================
// Notification Service - Local push notifications
// Used by Pomodoro timer to alert when sessions end.
// On web, notifications are silently skipped.
// ============================================================================

import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// Only import native notification plugin on non-web platforms
import 'notification_native.dart' if (dart.library.html) 'notification_web.dart'
    as notif_impl;

class NotificationService {
  bool _initialized = false;

  // ── Initialize notification channels ────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    try {
      await notif_impl.initNotifications();
      _initialized = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  // ── Show a notification ─────────────────────────────────────────────
  Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_initialized) return;
    await notif_impl.showNotification(title: title, body: body, id: id);
  }

  // ── Cancel notifications ────────────────────────────────────────────
  Future<void> cancelNotification(int id) async {
    if (!_initialized) return;
    await notif_impl.cancelNotification(id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await notif_impl.cancelAll();
  }
}
