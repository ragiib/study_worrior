// ============================================================================
// Settings Screen - App configuration
// Dark/Light mode toggle, notification controls, and app info.
// UI completely redesigned for a premium, educational-product aesthetic.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../../services/ai/ai_model_manager.dart';
import '../widgets/premium_page_header.dart';
import 'prepare_offline_ai_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumPageHeader(
              topLabel: 'Preferences',
              emoji: '⚙️',
              title: 'Settings',
              subtitle: 'Customize your learning experience',
            ),
            const SizedBox(height: 36),

            // ── AI Engine Section (The Centerpiece) ─────────────────
            const _SectionHeader(title: 'Offline AI Intelligence', icon: Icons.psychology_rounded),
            const SizedBox(height: 16),
            _buildAiStorageCard(context),
            const SizedBox(height: 36),

            // ── Appearance Section ──────────────────────────────────
            const _SectionHeader(title: 'Appearance', icon: Icons.palette_rounded),
            const SizedBox(height: 16),
            _buildThemeCard(context),
            const SizedBox(height: 36),

            // ── Notifications Section ───────────────────────────────
            const _SectionHeader(title: 'Notifications', icon: Icons.notifications_active_rounded),
            const SizedBox(height: 16),
            _buildNotificationCard(context),
            const SizedBox(height: 36),

            // ── About Section ───────────────────────────────────────
            const _SectionHeader(title: 'About', icon: Icons.info_rounded),
            const SizedBox(height: 16),
            _buildAboutCard(context),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── AI Storage Card (Premium Redesign) ──────────────────────────────
  Widget _buildAiStorageCard(BuildContext context) {
    return Consumer<AiModelManager>(
      builder: (context, manager, _) {
        final activeConfig = manager.activeModelConfig;
        
        // Define badge semantics based on tier
        String badgeEmoji;
        String badgeText;
        Color badgeColor;
        
        switch (activeConfig.tier) {
          case AiModelTier.tier4GB:
            badgeEmoji = '⚡';
            badgeText = 'Fast';
            badgeColor = Colors.blue;
            break;
          case AiModelTier.tier6GB:
            badgeEmoji = '🧠';
            badgeText = 'Balanced';
            badgeColor = AppTheme.accentPurple;
            break;
          case AiModelTier.tier8GB:
            badgeEmoji = '🚀';
            badgeText = 'Advanced';
            badgeColor = AppTheme.accentOrange;
            break;
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (manager.isDownloaded)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(15),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(badgeEmoji, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  badgeText,
                                  style: TextStyle(
                                    color: badgeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.check_circle_rounded, color: badgeColor, size: 24),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        activeConfig.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This model operates completely offline, ensuring total privacy and fast responses without internet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildDetailChip(context, Icons.sd_storage_rounded, 'Uses ${activeConfig.displaySize}'),
                          const SizedBox(width: 12),
                          _buildDetailChip(context, Icons.memory_rounded, 'Needs ${activeConfig.requiredRamGB}GB+ RAM'),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey.withAlpha(100)),
                      const SizedBox(height: 16),
                      const Text(
                        'No Model Downloaded',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download an AI model to use Note Generator, Doubt Solver, and Voice Teacher offline.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => PrepareOfflineAiScreen(
                                onDownloadComplete: () {
                                  Navigator.pop(ctx);
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: Text(manager.isDownloaded ? 'Change Model' : 'Download Model'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (manager.isDownloaded) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _confirmDeleteModel(context, manager, activeConfig),
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: Colors.red,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withAlpha(15),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        tooltip: 'Delete Model',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteModel(BuildContext context, AiModelManager manager, AiModelConfig config) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete AI Model?'),
          ],
        ),
        content: Text(
          'This will delete ${config.name} and free up ${config.displaySize} of space.\n\n'
          'AI features will require downloading a model again to function offline.',
          style: const TextStyle(height: 1.5),
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await manager.deleteSpecificModel(config.tier);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Offline AI model deleted.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Theme Selection Card ────────────────────────────────────────────
  Widget _buildThemeCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Display Mode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _ThemeSegment(
                    label: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    isSelected: !themeProvider.isDarkMode && themeProvider.themeMode != ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 12),
                  _ThemeSegment(
                    label: 'Dark',
                    icon: Icons.nightlight_round,
                    isSelected: themeProvider.isDarkMode && themeProvider.themeMode != ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                  const SizedBox(width: 12),
                  _ThemeSegment(
                    label: 'System',
                    icon: Icons.settings_brightness_rounded,
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Notification Controls ───────────────────────────────────────────
  Widget _buildNotificationCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                iconColor: AppTheme.secondaryColor,
                title: 'Push Notifications',
                subtitle: 'Timer alerts and study reminders',
                trailing: Switch(
                  value: themeProvider.notificationsEnabled,
                  onChanged: (_) => themeProvider.toggleNotifications(),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── About Card ──────────────────────────────────────────────────────
  Widget _buildAboutCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.primaryColor,
            title: 'Study Warrior',
            subtitle: 'Version 1.0.0',
            trailing: null,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 76, right: 24),
            child: Container(height: 1, color: Colors.grey.withAlpha(20)),
          ),
          const _SettingsTile(
            icon: Icons.favorite_rounded,
            iconColor: AppTheme.accentOrange,
            title: 'Made with ❤️',
            subtitle: 'Stay focused, stay strong!',
            trailing: null,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Section Header (Premium Redesign)
// ════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Settings Tile (Premium Redesign)
// ════════════════════════════════════════════════════════════════════════════
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Theme Segment Button (Premium Redesign)
// ════════════════════════════════════════════════════════════════════════════
class _ThemeSegment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.withAlpha(40),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? Colors.white : Colors.grey, 
                size: 24
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
