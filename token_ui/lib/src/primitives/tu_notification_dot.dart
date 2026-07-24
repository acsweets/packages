import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Notification badge over [child], typically top-right.
class TuNotificationDot extends StatelessWidget {
  const TuNotificationDot({
    super.key,
    required this.text,
    this.offset,
    this.size,
    this.textStyle,
    this.textColor,
    this.backgroundColor,
    this.border,
    this.hideEmpty = true,
    this.child,
  });

  /// Shows [count], capped as `"$maxCount+"`. Empty when zero and [hideZero].
  const TuNotificationDot.number({
    super.key,
    required int count,
    int maxCount = 99,
    this.offset,
    this.size,
    this.textStyle,
    this.textColor,
    this.backgroundColor,
    this.border,
    bool hideZero = true,
    this.child,
  }) : text = count > maxCount
           ? '$maxCount+'
           : count <= 0 && hideZero
           ? ''
           : '$count',
       hideEmpty = true;

  final String text;
  final Offset? offset;
  final double? size;
  final TextStyle? textStyle;
  final Color? textColor;
  final Color? backgroundColor;
  final Border? border;
  final bool hideEmpty;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.styles;
    final dotSize = size ?? 36.aw;

    if (hideEmpty && text.isEmpty) {
      return child ?? SizedBox(width: dotSize, height: dotSize);
    }

    final dotStyle = textStyle ?? styles.title[7];
    final dotColor = textColor ?? colors.text.primary;
    final dotBackgroundColor = backgroundColor ?? colors.error.primary;
    final dot = Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        border: border,
        borderRadius: BorderRadius.circular(dotSize / 2),
        color: dotBackgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.all(2.aw),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: dotStyle + dotColor),
          ),
        ),
      ),
    );

    if (child case final widget?) {
      final dotOffset = offset ?? Offset(dotSize / 2, dotSize / 2);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          widget,
          Positioned(right: -dotOffset.dx, top: -dotOffset.dy, child: dot),
        ],
      );
    }

    return dot;
  }
}
