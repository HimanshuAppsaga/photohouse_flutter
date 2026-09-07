import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TabItemData {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  const TabItemData({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

/// A modern floating glassmorphic bottom navigation dock with glowing animated indicators.
class ModernFloatingBottomDock extends StatelessWidget {
  final int selectedIndex;
  final List<TabItemData> items;
  final Function(int) onTabSelected;

  const ModernFloatingBottomDock({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      height: 68,
      decoration: BoxDecoration(
        color: palette.cardBg.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.5 : 0.08),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: palette.accentAmber.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = selectedIndex == index;
            final displayIcon = isSelected ? (item.activeIcon ?? item.icon) : item.icon;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? palette.accentAmber.withValues(alpha: 0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? palette.accentAmber.withValues(alpha: 0.4)
                          : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: palette.accentAmber.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.18 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          displayIcon,
                          color: isSelected ? palette.accentAmber : palette.textMuted,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          color: isSelected ? palette.accentAmber : palette.textMuted,
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          letterSpacing: isSelected ? 0.3 : 0.0,
                        ),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Animated Floating Active Glow Indicator Pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        height: isSelected ? 3 : 0,
                        width: isSelected ? 16 : 0,
                        decoration: BoxDecoration(
                          color: palette.accentAmber,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: palette.accentAmber,
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// A modern segmented tab bar with smooth pill animation for active tab switching.
class ModernSegmentedTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> tabs;
  final List<int>? counts;
  final Function(int) onTabSelected;

  const ModernSegmentedTabBar({
    super.key,
    required this.selectedIndex,
    required this.tabs,
    this.counts,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedIndex == index;
          final count = counts != null && index < counts!.length
              ? counts![index]
              : null;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabSelected(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? palette.cardBg : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(
                          color: palette.accentAmber.withValues(alpha: 0.3),
                          width: 1,
                        )
                      : Border.all(color: Colors.transparent),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: palette.isDark ? 0.3 : 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? palette.textPrimary : palette.textMuted,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? palette.accentAmber.withValues(alpha: 0.2)
                              : palette.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: isSelected ? palette.accentAmber : palette.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
