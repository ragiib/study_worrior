// ============================================================================
// Study Warrior App - Root Widget
// Configures theming, navigation, and the main shell.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_shell.dart';

class StudyWarriorApp extends StatelessWidget {
  const StudyWarriorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Study Warrior',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const MainShell(),
        );
      },
    );
  }
}
