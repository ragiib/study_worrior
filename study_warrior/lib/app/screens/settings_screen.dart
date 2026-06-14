// ============================================================================
// Settings Screen - App configuration
// Dark/Light mode toggle, notification controls, and app info.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_page_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumPageHeader(
              topLabel: 'Preferences',
              emoji: '⚙️',
              title: 'Settings',
              subtitle: 'Customize your experience',
            ),
            SizedBox(height: 28),

            // ── Appearance Section ──────────────────────────────────
            _SectionHeader(title: 'Appearance'),
            SizedBox(height: 12),
            _buildThemeCard(context),
            SizedBox(height: 24),

            // ── Notifications Section ───────────────────────────────
            _SectionHeader(title: 'Notifications'),
            SizedBox(height: 12),
            _buildNotificationCard(context),
            SizedBox(height: 24),

            // ── About Section ───────────────────────────────────────
            _SectionHeader(title: 'About'),
            SizedBox(height: 12),
            _buildAboutCard(context),
          ],
        ),
      ),
    );
  }

  // ── Theme Selection Card ────────────────────────────────────────────
  Widget _buildThemeCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Dark/Light mode toggle
              _SettingsTile(
                icon: themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                iconColor: themeProvider.isDarkMode
                    ? AppTheme.accentPurple
                    : AppTheme.accentYellow,
                title: 'Dark Mode',
                subtitle: themeProvider.isDarkMode
                    ? 'Currently using dark theme'
                    : 'Currently using light theme',
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              Divider(height: 32, color: Colors.grey.withAlpha(30)),
              // Theme mode selector
              Row(
                children: [
                  _ThemeOption(
                    label: 'Light',
                    icon: Icons.wb_sunny_rounded,
                    isSelected: !themeProvider.isDarkMode,
                    color: AppTheme.accentYellow,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  SizedBox(width: 12),
                  _ThemeOption(
                    label: 'Dark',
                    icon: Icons.nightlight_round,
                    isSelected: themeProvider.isDarkMode,
                    color: AppTheme.accentPurple,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                  SizedBox(width: 12),
                  _ThemeOption(
                    label: 'System',
                    icon: Icons.settings_brightness_rounded,
                    isSelected: themeProvider.themeMode == ThemeMode.system,
                    color: AppTheme.primaryColor,
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
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.notifications_rounded,
                iconColor: AppTheme.secondaryColor,
                title: 'Push Notifications',
                subtitle: 'Timer alerts and reminders',
                trailing: Switch(
                  value: themeProvider.notificationsEnabled,
                  onChanged: (_) => themeProvider.toggleNotifications(),
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              Divider(height: 32, color: Colors.grey.withAlpha(30)),
              _SettingsTile(
                icon: Icons.timer_rounded,
                iconColor: AppTheme.primaryColor,
                title: 'Timer Alerts',
                subtitle: 'Notify when Pomodoro sessions end',
                trailing: Icon(
                  themeProvider.notificationsEnabled
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: themeProvider.notificationsEnabled
                      ? AppTheme.secondaryColor
                      : Colors.grey,
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.primaryColor,
            title: 'Study Warrior',
            subtitle: 'Version 1.0.0',
            trailing: null,
          ),

          Divider(height: 32, color: Colors.grey.withAlpha(30)),
          _SettingsTile(
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
// Section Header
// ════════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Settings Tile
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
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Theme Option Button
// ════════════════════════════════════════════════════════════════════════════
class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withAlpha(25) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withAlpha(40),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
              SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
