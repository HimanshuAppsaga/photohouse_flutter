import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ToastType {
  success,
  info,
  warning,
  error,
}

class AppToast {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    // Dismiss any active overlay before showing new one
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlayState = Overlay.of(context);

    final palette = AppThemePalette.of(context);

    Color iconColor;
    Color iconBg;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        iconColor = palette.successGreen;
        iconBg = palette.successGreen.withValues(alpha: 0.15);
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.warning:
        iconColor = palette.accentAmber;
        iconBg = palette.accentAmber.withValues(alpha: 0.15);
        iconData = Icons.warning_amber_rounded;
        break;
      case ToastType.error:
        iconColor = palette.dangerRed;
        iconBg = palette.dangerRed.withValues(alpha: 0.15);
        iconData = Icons.error_outline_rounded;
        break;
      case ToastType.info:
        iconColor = palette.accentAmber;
        iconBg = palette.accentAmber.withValues(alpha: 0.15);
        iconData = Icons.notifications_active_rounded;
        break;
    }

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return _TopToastWidget(
          message: message,
          iconColor: iconColor,
          iconBg: iconBg,
          iconData: iconData,
          duration: duration,
          onDismissed: () {
            if (_currentOverlay == overlayEntry) {
              overlayEntry.remove();
              _currentOverlay = null;
            }
          },
        );
      },
    );

    _currentOverlay = overlayEntry;
    overlayState.insert(overlayEntry);
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final Color iconColor;
  final Color iconBg;
  final IconData iconData;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopToastWidget({
    required this.message,
    required this.iconColor,
    required this.iconBg,
    required this.iconData,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    // Auto dismiss timer
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    if (_controller.isAnimating) return;
    await _controller.reverse();
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final palette = AppThemePalette.of(context);

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _dismiss();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: palette.isDark
                      ? const Color(0xFF1E1E22).withValues(alpha: 0.96)
                      : const Color(0xFFFFFFFF).withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: palette.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: palette.isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: widget.iconColor.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.iconData,
                        color: widget.iconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.close,
                      color: palette.textMuted,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
