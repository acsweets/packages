import 'package:flutter/material.dart';

/// Wraps [child] with a positioned badge label.
class TuBadgeWrapper extends StatelessWidget {
  const TuBadgeWrapper({
    super.key,
    required this.child,
    required this.badgeText,
    this.alignmentX = 1.0,
    this.alignmentY = -1.0,
    this.backgroundColor,
    this.gradient,
    this.textColor = Colors.white,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius = 16,
    this.badgeSize,
    this.borderWidth,
    this.borderColor,
    this.borderGradient,
    this.offset = Offset.zero,
  });

  final Widget child;
  final String badgeText;

  /// -1 left … 1 right
  final double alignmentX;

  /// -1 top … 1 bottom
  final double alignmentY;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color textColor;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final double borderRadius;
  final Size? badgeSize;
  final double? borderWidth;
  final Color? borderColor;
  final Gradient? borderGradient;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: alignmentY <= 0 ? offset.dy : null,
          bottom: alignmentY > 0 ? offset.dy : null,
          left: alignmentX <= 0 ? offset.dx : null,
          right: alignmentX > 0 ? offset.dx : null,
          child: _buildBadge(),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    final bw = borderWidth;
    if (bw != null && bw > 0 && borderGradient != null) {
      return Container(
        width: badgeSize?.width,
        height: badgeSize?.height,
        decoration: BoxDecoration(
          gradient: borderGradient,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(borderRadius),
            bottomRight: Radius.circular(borderRadius),
          ),
        ),
        padding: EdgeInsets.only(top: bw, right: bw, bottom: bw),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? (backgroundColor ?? Colors.grey) : null,
            gradient: gradient,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(borderRadius - bw),
              bottomRight: Radius.circular(borderRadius - bw),
            ),
          ),
          child: Center(child: _badgeText()),
        ),
      );
    }

    final bc = borderColor;
    return Container(
      width: badgeSize?.width,
      height: badgeSize?.height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? Colors.grey) : null,
        gradient: gradient,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(borderRadius),
          bottomRight: Radius.circular(borderRadius),
        ),
        border: bw != null && bc != null
            ? Border.all(color: bc, width: bw)
            : null,
      ),
      child: Center(child: _badgeText()),
    );
  }

  Widget _badgeText() {
    return Text(
      badgeText,
      style:
          textStyle?.copyWith(color: textColor) ??
          TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
