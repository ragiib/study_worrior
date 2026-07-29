import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../theme/app_theme.dart';
import 'quiz_result_screen.dart';

class QuizPlayingScreen extends StatefulWidget {
  final Quiz quiz;

  const QuizPlayingScreen({super.key, required this.quiz});

  @override
  State<QuizPlayingScreen> createState() => _QuizPlayingScreenState();
}

class _QuizPlayingScreenState extends State<QuizPlayingScreen> {
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {};

  void _nextQuestion() {
    if (_currentIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _submitQuiz();
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

  void _submitQuiz() {
    // Check if all questions are answered
    if (_userAnswers.length < widget.quiz.questions.length) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Quiz'),
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
    final result = QuizResult(
      quiz: widget.quiz,
      userAnswers: _userAnswers,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quiz.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Error')),
        body: const Center(child: Text('No questions available in this quiz.')),
      );
    }

    final question = widget.quiz.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.quiz.questions.length;
    final selectedOption = _userAnswers[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question \${_currentIndex + 1} of \${widget.quiz.questions.length}'),
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
