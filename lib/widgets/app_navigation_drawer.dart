import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_logo.dart';

class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);

    return Drawer(
      backgroundColor: palette.bgDarker,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with App Logo & Title
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: palette.isDarkMode ? Colors.white : palette.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accentPrimary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: const AppLogo(size: 34),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PhotoHouse',
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Desktop Sync',
                        style: TextStyle(
                          color: palette.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Divider(color: palette.border, height: 1),
              const SizedBox(height: 20),
              // Navigation Items List
              _buildNavItem(
                context: context,
                palette: palette,
                index: 0,
                icon: Icons.calendar_today_outlined,
                label: 'Events',
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                context: context,
                palette: palette,
                index: 1,
                icon: Icons.upload_outlined,
                label: 'Queue',
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                context: context,
                palette: palette,
                index: 2,
                icon: Icons.credit_card_outlined,
                label: 'Subscription',
              ),
              const SizedBox(height: 8),
              _buildNavItem(
                context: context,
                palette: palette,
                index: 3,
                icon: Icons.settings_outlined,
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required AppThemePalette palette,
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? palette.cardBg : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: palette.accentPrimary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: palette.accentPrimary.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Left Active Indicator Strip
                if (isSelected)
                  Container(
                    width: 3.5,
                    height: 20,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: palette.accentPrimary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accentPrimary,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 4),
                Icon(
                  icon,
                  color: palette.accentPrimary,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? palette.textPrimary : palette.textSecondary,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
