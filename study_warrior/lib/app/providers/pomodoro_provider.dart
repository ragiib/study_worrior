// ============================================================================
// Pomodoro Provider - Timer state management
// Supports standard 25/5 and custom durations.
// Handles start, pause, resume, reset, and session completion notifications.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../services/notification_service.dart';
import '../../services/database_service.dart';
import '../../models/study_session_model.dart';

enum PomodoroState { idle, running, paused, breakTime }

class PomodoroProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  final DatabaseService _dbService;

  // ── Timer Configuration ─────────────────────────────────────────────
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _remainingSeconds = 25 * 60;
  int _completedSessions = 0;

  PomodoroState _state = PomodoroState.idle;
  Timer? _timer;
  bool _isBreak = false;

  PomodoroProvider(this._notificationService, this._dbService);

  // ── Getters ─────────────────────────────────────────────────────────
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  int get remainingSeconds => _remainingSeconds;
  int get completedSessions => _completedSessions;
  PomodoroState get state => _state;
  bool get isBreak => _isBreak;
  bool get isRunning => _state == PomodoroState.running;
  bool get isPaused => _state == PomodoroState.paused;
  bool get isIdle => _state == PomodoroState.idle;

  /// Formatted time display (MM:SS)
  String get timeDisplay {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    final total = _isBreak ? _breakMinutes * 60 : _workMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  // ── Set Custom Duration ─────────────────────────────────────────────
  void setWorkMinutes(int minutes) {
    _workMinutes = minutes;
    if (_state == PomodoroState.idle && !_isBreak) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }

  void setBreakMinutes(int minutes) {
    _breakMinutes = minutes;
    if (_state == PomodoroState.idle && _isBreak) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }

  // ── Start / Resume Timer ────────────────────────────────────────────
  void start() {
    if (_state == PomodoroState.running) return;

    _state = PomodoroState.running;
    _timer = Timer.periodic(Duration(seconds: 1), (_) => _tick());
    notifyListeners();
  }

  // ── Pause Timer ─────────────────────────────────────────────────────
  void pause() {
    _timer?.cancel();
    _state = PomodoroState.paused;
    notifyListeners();
  }

  // ── Resume from pause ───────────────────────────────────────────────
  void resume() {
    start();
  }

  // ── Reset Timer ─────────────────────────────────────────────────────
  void reset() {
    _timer?.cancel();
    _state = PomodoroState.idle;
    _isBreak = false;
    _remainingSeconds = _workMinutes * 60;
    notifyListeners();
  }

  // ── Internal tick handler ───────────────────────────────────────────
  void _tick() {
    if (_remainingSeconds > 0) {
      _remainingSeconds--;
      notifyListeners();
    } else {
      _timer?.cancel();
      _onSessionComplete();
    }
  }

  // ── Session completion logic ────────────────────────────────────────
  void _onSessionComplete() {
    if (_isBreak) {
      // Break finished → ready for new work session
      _notificationService.showNotification(
        title: '☕ Break Over!',
        body: 'Time to get back to studying, warrior!',
        id: 1,
      );
      _isBreak = false;
      _remainingSeconds = _workMinutes * 60;
      _state = PomodoroState.idle;
    } else {
      // Work session finished → start break
      _completedSessions++;
      
      // Save study session to database
      final session = StudySession(
        id: const Uuid().v4(),
        durationMinutes: _workMinutes,
        date: DateTime.now(),
        type: 'pomodoro',
      );
      _dbService.insertSession(session);

      _notificationService.showNotification(
        title: '🎉 Session Complete!',
        body: 'Great job! Take a well-deserved break.',
        id: 0,
      );
      _isBreak = true;
      _remainingSeconds = _breakMinutes * 60;
      _state = PomodoroState.breakTime;
    }
    notifyListeners();
  }

  // ── Start break manually ────────────────────────────────────────────
  void startBreak() {
    _isBreak = true;
    _remainingSeconds = _breakMinutes * 60;
    start();
  }

  // ── Skip break ──────────────────────────────────────────────────────
  void skipBreak() {
    _timer?.cancel();
    _isBreak = false;
    _remainingSeconds = _workMinutes * 60;
    _state = PomodoroState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
