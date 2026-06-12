// ============================================================================
// Study Warrior - Main Entry Point
// A premium study productivity app with dashboard, task manager,
// pomodoro timer, and habit tracker.
// ============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/providers/theme_provider.dart';
import 'app/providers/task_provider.dart';
import 'app/providers/pomodoro_provider.dart';
import 'app/providers/habit_provider.dart';
import 'app/providers/dashboard_provider.dart';
import 'app/providers/ai_notes_provider.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized before any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for optimal UX (not supported on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Initialize core services (notifications are native-only)
  final databaseService = DatabaseService();
  final notificationService = NotificationService();

  try {
    await databaseService.initialize();
  } catch (e) {
    debugPrint('Database init skipped: $e');
  }

  if (!kIsWeb) {
    try {
      await notificationService.initialize();
    } catch (e) {
      debugPrint('Notification init skipped: $e');
    }
  }

  // Launch the app with all providers
  runApp(
    MultiProvider(
      providers: [
        // Theme management (dark/light mode)
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // Task management with database persistence
        ChangeNotifierProvider(
          create: (_) {
            final provider = TaskProvider(databaseService);
            provider.loadTasks();
            return provider;
          },
        ),
        // Pomodoro timer with notification support
        ChangeNotifierProvider(
          create: (_) => PomodoroProvider(notificationService, databaseService),
        ),
        // Habit tracking with streaks
        ChangeNotifierProvider(
          create: (_) {
            final provider = HabitProvider(databaseService);
            provider.loadHabits();
            return provider;
          },
        ),
        // Dashboard aggregation
        ChangeNotifierProvider(
          create: (_) {
            final provider = DashboardProvider(databaseService);
            provider.loadStats();
            return provider;
          },
        ),
        // AI Notes Management
        ChangeNotifierProvider(
          create: (_) => AiNotesProvider(databaseService),
        ),
      ],
      child: const StudyWarriorApp(),
    ),
  );
}
