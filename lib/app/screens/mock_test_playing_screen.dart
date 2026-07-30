import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../theme/app_theme.dart';
import 'mock_test_result_screen.dart';

class MockTestPlayingScreen extends StatefulWidget {
  final Quiz quiz;
  final int timerMinutes; // 0 means off

  const MockTestPlayingScreen({
    super.key, 
    required this.quiz,
    required this.timerMinutes,
  });

  @override
  State<MockTestPlayingScreen> createState() => _MockTestPlayingScreenState();
}

class _MockTestPlayingScreenState extends State<MockTestPlayingScreen> {
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {};
  
  Timer? _timer;
  int _remainingSeconds = 0;
  int _timeTakenSeconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.timerMinutes > 0) {
      _remainingSeconds = widget.timerMinutes * 60;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
            _timeTakenSeconds++;
          } else {
            _timer?.cancel();
            _autoSubmitTest();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _submitTest();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _userAnswers[_currentIndex] = optionIndex;
    });
  }

  void _autoSubmitTest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time is up! Submitting test...'),
        backgroundColor: Colors.orange,
      ),
    );
    _finish();
  }

  void _submitTest() {
    // Check if all questions are answered
    if (_userAnswers.length < widget.quiz.questions.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Test'),
          content: const Text('You have unanswered questions. Are you sure you want to submit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _finish();
              },
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
      return;
    }
    
    _finish();
  }

  void _finish() {
    _timer?.cancel();
    final result = QuizResult(
      quiz: widget.quiz,
      userAnswers: _userAnswers,
      timeTakenSeconds: widget.timerMinutes > 0 ? _timeTakenSeconds : null,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MockTestResultScreen(result: result),
      ),
    );
  }

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test Error')),
        body: const Center(child: Text('No questions available.')),
      );
    }

    final question = widget.quiz.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.quiz.questions.length;
    final selectedOption = _userAnswers[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Question ${_currentIndex + 1} of ${widget.quiz.questions.length}'),
            if (widget.timerMinutes > 0)
              Text(
                'Time: ${_formatTime(_remainingSeconds)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _remainingSeconds <= 60 ? Colors.red.shade400 : Colors.grey,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withAlpha(50),
              color: AppTheme.primaryColor,
              minHeight: 6,
            ),
            // Question Grid Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(widget.quiz.questions.length, (index) {
                    final isAnswered = _userAnswers.containsKey(index);
                    final isCurrent = index == _currentIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent 
                              ? AppTheme.primaryColor 
                              : (isAnswered ? Colors.green.shade500 : Colors.grey.withAlpha(50)),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: (isCurrent || isAnswered) ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.question,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(question.options.length, (index) {
                      final isSelected = selectedOption == index;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _selectOption(index),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? AppTheme.primaryColor.withAlpha(30)
                                  : Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? AppTheme.primaryColor
                                    : Colors.grey.withAlpha(50),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppTheme.primaryColor : Colors.grey,
                                      width: 2,
                                    ),
                                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousQuestion,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextQuestion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentIndex < widget.quiz.questions.length - 1 ? 'Next' : 'Submit',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
