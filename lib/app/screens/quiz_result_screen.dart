import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import '../theme/app_theme.dart';
import 'ai_quiz_generator_screen.dart';

class QuizResultScreen extends StatelessWidget {
  final QuizResult result;

  const QuizResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final int score = result.score;
    final int total = result.quiz.questions.length;
    final double percentage = result.percentage;
    
    String message = 'Good Job!';
    Color scoreColor = AppTheme.primaryColor;
    if (percentage == 100) {
      message = 'Perfect Score! 🏆';
      scoreColor = Colors.green;
    } else if (percentage >= 80) {
      message = 'Excellent! 🌟';
      scoreColor = Colors.green;
    } else if (percentage >= 60) {
      message = 'Well done! 👍';
      scoreColor = Colors.orange;
    } else {
      message = 'Keep practicing! 💪';
      scoreColor = Colors.red;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
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
                  const SizedBox(height: 16),
                  Text(
                    'You answered $score out of $total questions correctly.',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: total,
                itemBuilder: (context, index) {
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
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
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
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (userAnswer == null) ...[
                            const Text(
                              'Your Answer: Skipped',
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            'Correct Answer: ${question.options[question.correctAnswerIndex]}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
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
                },
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
                            builder: (context) => const AiQuizGeneratorScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('New Quiz'),
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
}
