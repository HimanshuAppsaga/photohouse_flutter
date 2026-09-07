import 'package:flutter/material.dart';

/// A reusable widget that displays the Photo House logo.
class AppLogo extends StatelessWidget {
  /// Size (width and height) of the logo image.
  final double size;

  /// Whether to display the logo inside a styled card container with a shadow.
  final bool showCard;

  /// Optional padding around the logo when [showCard] is true.
  final double padding;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showCard = false,
    this.padding = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = Image.asset(
      'assets/images/logo.png',
      height: size,
      width: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.camera_alt,
        size: size,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    if (!showCard) {
      return imageWidget;
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.17),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: size * 0.14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: imageWidget,
    );
  }
}
