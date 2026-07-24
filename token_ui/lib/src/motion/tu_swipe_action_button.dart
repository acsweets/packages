import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Swipe-linked action button (scales / recolors with drag progress).
class TuSwipeActionButton extends StatelessWidget {
  static double get idleSize => 120.aw;
  static double get maxSize => 144.aw;

  final Widget Function(Color color) iconBuilder;
  final Color backgroundColor;
  final Color iconColor;
  final Color? activeBackgroundColor;
  final Color? activeIconColor;
  final String label;
  final VoidCallback onTap;

  /// -1 left, 1 right.
  final int direction;

  /// Progress from [TuSwipeCardStack], -1 ~ 1.
  final double progress;

  const TuSwipeActionButton({
    super.key,
    required this.iconBuilder,
    required this.backgroundColor,
    required this.iconColor,
    required this.label,
    required this.onTap,
    required this.direction,
    required this.progress,
    this.activeBackgroundColor,
    this.activeIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final signedProgress = direction < 0 ? -progress : progress;
    final activeAmount = signedProgress.clamp(0.0, 1.0);
    final scale = 1.0 + activeAmount * ((maxSize / idleSize) - 1.0);

    final bg = Color.lerp(
      backgroundColor,
      activeBackgroundColor ?? backgroundColor,
      activeAmount,
    );
    final fg = Color.lerp(
      iconColor,
      activeIconColor ?? iconColor,
      activeAmount,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: idleSize,
        height: idleSize,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              child: Container(
                width: idleSize,
                height: idleSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
                child: iconBuilder(fg ?? iconColor),
              ),
            ),
            Positioned(
              top: idleSize + 12.aw,
              left: -(280.aw - idleSize) / 2,
              width: 280.aw,
              child: Opacity(
                opacity: activeAmount,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.asp,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
