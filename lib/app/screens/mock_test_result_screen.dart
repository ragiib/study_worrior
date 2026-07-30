import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../theme/app_theme.dart';
import 'mock_test_generator_screen.dart';

class MockTestResultScreen extends StatelessWidget {
  final QuizResult result;

  const MockTestResultScreen({super.key, required this.result});

  String _formatTime(int seconds) {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final int score = result.score;
    final int total = result.quiz.questions.length;
    final double percentage = result.percentage;
    
    int correct = 0;
    int incorrect = 0;
    int unanswered = 0;
    Map<String, int> topicWeaknesses = {};

    for (int i = 0; i < total; i++) {
      final q = result.quiz.questions[i];
      final ans = result.userAnswers[i];
      if (ans == null) {
        unanswered++;
      } else if (ans == q.correctAnswerIndex) {
        correct++;
      } else {
        incorrect++;
        if (q.topic != null && q.topic!.isNotEmpty) {
          topicWeaknesses[q.topic!] = (topicWeaknesses[q.topic!] ?? 0) + 1;
        }
      }
    }

    // Sort weaknesses by most incorrect
    final sortedWeaknesses = topicWeaknesses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String message = 'Good Job!';
    Color scoreColor = AppTheme.primaryColor;
    if (percentage == 100) {
      message = 'Perfect Score! 🏆';
      scoreColor = Colors.green.shade600;
    } else if (percentage >= 80) {
      message = 'Excellent! 🌟';
      scoreColor = Colors.green.shade600;
    } else if (percentage >= 60) {
      message = 'Well done! 👍';
      scoreColor = Colors.orange.shade600;
    } else {
      message = 'Keep practicing! 💪';
      scoreColor = Colors.red.shade400;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Test Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      color: Theme.of(context).cardTheme.color,
                      child: Column(
                        children: [
                          Text(
                            message,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: percentage / 100,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.grey.withAlpha(50),
                                  color: scoreColor,
                                ),
                              ),
                              Text(
                                '${percentage.toInt()}%',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Stats Grid
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem('Correct', correct.toString(), Colors.green.shade600),
                              _buildStatItem('Incorrect', incorrect.toString(), Colors.red.shade400),
                              _buildStatItem('Unanswered', unanswered.toString(), Colors.orange.shade600),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (result.timeTakenSeconds != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withAlpha(30),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.timer, size: 20, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Time taken: ${_formatTime(result.timeTakenSeconds!)}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (sortedWeaknesses.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Topics to Review',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: sortedWeaknesses.map((e) => Chip(
                            label: Text('${e.key} (${e.value} wrong)'),
                            backgroundColor: Colors.red.shade50,
                            labelStyle: TextStyle(color: Colors.red.shade900),
                          )).toList(),
                        ),
                      ),
                    ],

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detailed Review',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          ...List.generate(total, (index) {
                            final question = result.quiz.questions[index];
                            final userAnswer = result.userAnswers[index];
                            final isCorrect = userAnswer == question.correctAnswerIndex;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          userAnswer == null 
                                            ? Icons.help_outline
                                            : (isCorrect ? Icons.check_circle : Icons.cancel),
                                          color: userAnswer == null
                                            ? Colors.orange.shade600
                                            : (isCorrect ? Colors.green.shade600 : Colors.red.shade400),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Q${index + 1}: ${question.question}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (!isCorrect && userAnswer != null) ...[
                                      Text(
                                        'Your Answer: ${question.options[userAnswer]}',
                                        style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    if (userAnswer == null) ...[
                                      Text(
                                        'Your Answer: Skipped',
                                        style: TextStyle(color: Colors.orange.shade600, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                    Text(
                                      'Correct Answer: ${question.options[question.correctAnswerIndex]}',
                                      style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).scaffoldBackgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              question.explanation,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MockTestGeneratorScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('New Mock Test'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
