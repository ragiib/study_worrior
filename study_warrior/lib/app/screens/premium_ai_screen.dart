import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_feature_card.dart';
import '../widgets/premium_page_header.dart';
import 'ai_notes_generator_screen.dart';
import 'premium_upgrade_screen.dart';

class PremiumAiScreen extends StatelessWidget {
  const PremiumAiScreen({super.key});

  void _handleLockedFeatureTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PremiumUpgradeScreen()),
    );
  }

  void _navigateToAiNotes(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AiNotesGeneratorScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: const PremiumPageHeader(
                topLabel: 'Premium Tools',
                emoji: '✨',
                title: 'AI Assistant',
                subtitle: 'Supercharge your learning with AI-powered tools.',
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategorySection(
                  context,
                  title: '📚 Learn',
                  children: [
                    PremiumFeatureCard(
                      title: 'AI Notes\nGenerator',
                      icon: Icons.document_scanner_rounded,
                      gradientColors: const [Color(0xFF4F46E5), Color(0xFF3B82F6)],
                      isLocked: false, // Unlocked as requested
                      onTap: () => _navigateToAiNotes(context),
                    ),
                    PremiumFeatureCard(
                      title: 'AI Doubt\nSolver',
                      icon: Icons.live_help_rounded,
                      gradientColors: const [Color(0xFF059669), Color(0xFF10B981)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                    PremiumFeatureCard(
                      title: 'Voice\nTeacher',
                      icon: Icons.record_voice_over_rounded,
                      gradientColors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                    PremiumFeatureCard(
                      title: 'Best YouTube\nFinder',
                      icon: Icons.smart_display_rounded,
                      gradientColors: const [Color(0xFFDC2626), Color(0xFFEF4444)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                  ],
                ),
                _buildCategorySection(
                  context,
                  title: '📝 Practice',
                  children: [
                    PremiumFeatureCard(
                      title: 'AI Quiz\nGenerator',
                      icon: Icons.quiz_rounded,
                      gradientColors: const [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                    PremiumFeatureCard(
                      title: 'Mock Test\nGenerator',
                      icon: Icons.assignment_rounded,
                      gradientColors: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                    PremiumFeatureCard(
                      title: 'Important\nPredictor',
                      icon: Icons.lightbulb_rounded,
                      gradientColors: const [Color(0xFFEA580C), Color(0xFFF97316)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                  ],
                ),
                _buildCategorySection(
                  context,
                  title: '🎯 Improve',
                  children: [
                    PremiumFeatureCard(
                      title: 'Study\nPlanner',
                      icon: Icons.calendar_month_rounded,
                      gradientColors: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                    PremiumFeatureCard(
                      title: 'Answer Writing\nAssistant',
                      icon: Icons.draw_rounded,
                      gradientColors: const [Color(0xFFC026D3), Color(0xFFD946EF)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                    PremiumFeatureCard(
                      title: 'Analytics\nDashboard',
                      icon: Icons.analytics_rounded,
                      gradientColors: const [Color(0xFF4338CA), Color(0xFF6366F1)],
                      isLocked: true,
                      onTap: () => _handleLockedFeatureTap(context),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 140, // Fixed width for cards
                child: children[index],
              );
            },
          ),
        ),
      ],
    );
  }
}
