// ============================================================================
// Main Shell - Bottom navigation container
// Hosts all primary screens: Dashboard, Tasks, Timer, Habits, Settings.
// Uses a premium glassmorphism-inspired bottom nav bar.
// ============================================================================

import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'tasks_screen.dart';
import 'pomodoro_screen.dart';
import 'habits_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    DashboardScreen(
      onNavigate: (index) => setState(() => _currentIndex = index),
    ),
    const TasksScreen(),
    const PomodoroScreen(),
    const HabitsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            _buildNavItem(Icons.dashboard_rounded, 'Dashboard'),
            _buildNavItem(Icons.task_alt_rounded, 'Tasks'),
            _buildNavItem(Icons.timer_rounded, 'Timer'),
            _buildNavItem(Icons.auto_awesome_rounded, 'Habits'),
            _buildNavItem(Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
