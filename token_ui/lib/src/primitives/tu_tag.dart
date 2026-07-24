import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';
import '../theme/tu_text_styles.dart';

/// Generic tag for role / status labels.
class TuTag extends StatelessWidget {
  const TuTag({
    super.key,
    required this.text,
    this.size = TuTagSize.small,
    this.backgroundColor,
    this.gradient,
    this.textColor,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.border,
    this.borderWidth,
    this.borderGradient,
  });

  const TuTag.medium({
    super.key,
    required this.text,
    this.backgroundColor,
    this.gradient,
    this.textColor,
    this.textStyle,
    this.borderRadius,
    this.padding,
    this.border,
    this.borderWidth,
    this.borderGradient,
  }) : size = TuTagSize.medium;

  final String text;
  final TuTagSize size;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? textColor;
  final TextStyle? textStyle;
  final double? borderRadius;
  final EdgeInsets? padding;
  final BoxBorder? border;
  final double? borderWidth;
  final Gradient? borderGradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.styles;
    final effectiveTextStyle = _resolveTextStyle(styles);
    final effectiveTextColor = textColor ?? colors.text.primary;
    final effectiveBorderRadius = borderRadius ?? 4.ar;
    final effectivePadding = padding ?? _defaultPadding();
    final bw = borderWidth;

    final textWidget = Text(
      text,
      style: effectiveTextStyle + effectiveTextColor,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (bw != null && bw > 0 && borderGradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: borderGradient,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        padding: EdgeInsets.all(bw),
        child: Container(
          padding: effectivePadding,
          decoration: BoxDecoration(
            color: gradient == null
                ? (backgroundColor ?? colors.button.neutral)
                : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(effectiveBorderRadius - bw),
          ),
          child: textWidget,
        ),
      );
    }

    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? colors.button.neutral)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
        border: border,
      ),
      child: textWidget,
    );
  }

  TextStyle _resolveTextStyle(TuTextStyles styles) {
    final custom = textStyle;
    if (custom != null) {
      return custom;
    }
    return switch (size) {
      TuTagSize.small => styles.display[11],
      TuTagSize.medium => styles.meta[4],
    };
  }

  EdgeInsets _defaultPadding() {
    return switch (size) {
      TuTagSize.small => EdgeInsets.symmetric(horizontal: 6.aw, vertical: 4.aw),
      TuTagSize.medium => EdgeInsets.symmetric(
        horizontal: 12.aw,
        vertical: 4.aw,
      ),
    };
  }
}

enum TuTagSize {
  /// Compact: display/11, padding h6/v4.
  small,

  /// Regular: meta/4, padding h12/v4.
  medium,
}
