import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';
import '../theme/tu_colors.dart';
import '../theme/tu_text_styles.dart';

/// Token UI button with chain API:
/// `TuButton.primary.outline.xlarge.wide(onPressed: ..., label: '...')`.
class TuButton extends StatelessWidget {
  const TuButton._({
    super.key,
    this.onPressed,
    this.startIcon,
    this.endIcon,
    this.isLoading,
    this.isDisabled,
    this.label,
    required TuButtonTone tone,
    required TuButtonBorder border,
    required TuButtonSize size,
    required TuButtonWidth width,
  }) : _tone = tone,
       _border = border,
       _size = size,
       _width = width;

  factory TuButton.builder(
    TuButtonBuilder Function(TuButtonBuilder builder) builder, {
    Key? key,
    VoidCallback? onPressed,
    Widget? startIcon,
    Widget? endIcon,
    bool? isLoading,
    bool? isDisabled,
    String? label,
  }) => builder(TuButtonBuilder._()).call(
    key: key,
    onPressed: onPressed,
    startIcon: startIcon,
    endIcon: endIcon,
    isLoading: isLoading,
    isDisabled: isDisabled,
    label: label,
  );

  static TuButtonBuilder get primary => TuButtonBuilder._().primary;
  static TuButtonBuilder get neutral => TuButtonBuilder._().neutral;
  static TuButtonBuilder get secondary => TuButtonBuilder._().secondary;
  static TuButtonBuilder get error => TuButtonBuilder._().error;

  final VoidCallback? onPressed;
  final Widget? startIcon;
  final Widget? endIcon;
  final bool? isLoading;
  final bool? isDisabled;

  /// When null or empty, at least one icon must be provided.
  final String? label;

  final TuButtonTone _tone;
  final TuButtonBorder _border;
  final TuButtonSize _size;
  final TuButtonWidth _width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.styles;

    final toneStyle = _tone.resolve(colors);
    final (backgroundColor, borderColor, textColor) = switch (_border) {
      TuButtonBorder.solid => (
        toneStyle.backgroundColor,
        toneStyle.borderColor,
        toneStyle.textColor,
      ),
      TuButtonBorder.outline => (
        Colors.transparent,
        toneStyle.borderColor,
        toneStyle.borderColor,
      ),
      TuButtonBorder.ghost => (
        Colors.transparent,
        Colors.transparent,
        toneStyle.borderColor,
      ),
    };

    final textStyle = _size.textStyle(styles) + textColor;
    final disabled = isDisabled ?? false;
    final loading = isLoading ?? false;

    final normalizedLabel = label?.trim() ?? '';
    final hasLabel = normalizedLabel.isNotEmpty;
    final hasStartIcon = startIcon != null;
    final hasEndIcon = endIcon != null;

    assert(
      hasLabel || hasStartIcon || hasEndIcon,
      'When label is empty, at least one icon must be provided.',
    );

    final isSingleIconOnly =
        !hasLabel &&
        ((hasStartIcon && !hasEndIcon) || (!hasStartIcon && hasEndIcon));

    final resolvedWidth = switch (_width) {
      TuButtonWidth.fit => null,
      TuButtonWidth.wide => double.infinity,
      TuButtonWidth.fixedWidth => _size.fixedWidth,
    };

    final width = isSingleIconOnly ? _size.height : resolvedWidth;
    final height = _size.height;
    final iconHeight = _size.iconHeight;
    Widget childWidget;

    if (isSingleIconOnly) {
      final icon = startIcon ?? endIcon;
      childWidget = switch (icon) {
        final icon? => _TuButtonIcon(icon: icon, height: iconHeight),
        _ => SizedBox(width: width),
      };
    } else {
      childWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 8.aw,
        children: [
          if (startIcon case final icon?)
            _TuButtonIcon(icon: icon, height: iconHeight),
          if (hasLabel)
            Text(normalizedLabel, style: textStyle, softWrap: false),
          if (endIcon case final icon?)
            _TuButtonIcon(icon: icon, height: iconHeight),
        ],
      );
    }

    if (loading) {
      childWidget = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: 0, child: childWidget),
          SizedBox(
            width: iconHeight,
            height: iconHeight,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2.aw,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
        ],
      );
    }

    Widget button = GestureDetector(
      onTap: disabled || loading ? null : onPressed,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Container(
          width: width,
          height: height,
          padding: EdgeInsets.symmetric(horizontal: _size.horizontalPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: 2.aw,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(
              isSingleIconOnly ? height : 9999999,
            ),
          ),
          child: childWidget,
        ),
      ),
    );

    if (_width == TuButtonWidth.fit) {
      button = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [button],
      );
    }

    return button;
  }
}

/// Chain builder for [TuButton] tone / border / size / width.
class TuButtonBuilder {
  TuButtonBuilder._();

  var tone = TuButtonTone.primary;
  var border = TuButtonBorder.solid;
  var size = TuButtonSize.medium;
  var width = TuButtonWidth.fit;

  TuButtonBuilder get primary => this..tone = TuButtonTone.primary;
  TuButtonBuilder get neutral => this..tone = TuButtonTone.neutral;
  TuButtonBuilder get secondary => this..tone = TuButtonTone.secondary;
  TuButtonBuilder get error => this..tone = TuButtonTone.error;

  TuButtonBuilder get outline => this..border = TuButtonBorder.outline;
  TuButtonBuilder get ghost => this..border = TuButtonBorder.ghost;

  TuButtonBuilder get xlarge => this..size = TuButtonSize.xlarge;
  TuButtonBuilder get large => this..size = TuButtonSize.large;
  TuButtonBuilder get medium => this..size = TuButtonSize.medium;
  TuButtonBuilder get small => this..size = TuButtonSize.small;
  TuButtonBuilder get xsmall => this..size = TuButtonSize.xsmall;

  TuButtonBuilder get wide => this..width = TuButtonWidth.wide;
  TuButtonBuilder get fit => this..width = TuButtonWidth.fit;
  TuButtonBuilder get fixedWidth => this..width = TuButtonWidth.fixedWidth;

  TuButton call({
    Key? key,
    VoidCallback? onPressed,
    Widget? startIcon,
    Widget? endIcon,
    bool? isLoading,
    bool? isDisabled,
    String? label,
  }) {
    final normalizedLabel = label?.trim();
    final hasLabel = normalizedLabel != null && normalizedLabel.isNotEmpty;

    assert(
      hasLabel || startIcon != null || endIcon != null,
      'When label is empty, at least one icon must be provided.',
    );

    return TuButton._(
      key: key,
      onPressed: onPressed,
      startIcon: startIcon,
      endIcon: endIcon,
      isLoading: isLoading,
      isDisabled: isDisabled,
      label: normalizedLabel,
      tone: tone,
      border: border,
      size: size,
      width: width,
    );
  }
}

enum TuButtonTone { primary, neutral, secondary, error }

enum TuButtonBorder { solid, outline, ghost }

enum TuButtonSize { xlarge, large, medium, small, xsmall }

enum TuButtonWidth { fit, wide, fixedWidth }

extension on TuButtonTone {
  _ResolvedToneStyle resolve(TuColors colors) {
    return switch (this) {
      TuButtonTone.primary => _ResolvedToneStyle(
        textColor: colors.text.invert,
        backgroundColor: colors.button.primary,
        borderColor: colors.button.primary,
      ),
      TuButtonTone.neutral => _ResolvedToneStyle(
        textColor: colors.text.primary,
        backgroundColor: colors.button.neutral,
        borderColor: colors.button.neutral,
      ),
      TuButtonTone.secondary => _ResolvedToneStyle(
        textColor: colors.text.primary,
        backgroundColor: colors.button.secondary,
        borderColor: colors.button.secondary,
      ),
      TuButtonTone.error => _ResolvedToneStyle(
        textColor: colors.text.primary,
        backgroundColor: colors.error.secondary,
        borderColor: colors.error.secondary,
      ),
    };
  }
}

extension on TuButtonSize {
  double get horizontalPadding => switch (this) {
    TuButtonSize.xlarge => 32.aw,
    TuButtonSize.large || TuButtonSize.medium => 24.aw,
    TuButtonSize.small || TuButtonSize.xsmall => 16.aw,
  };

  double get height => switch (this) {
    TuButtonSize.xlarge => 80.aw,
    TuButtonSize.large => 72.aw,
    TuButtonSize.medium => 64.aw,
    TuButtonSize.small => 56.aw,
    TuButtonSize.xsmall => 48.aw,
  };

  TextStyle textStyle(TuTextStyles styles) => switch (this) {
    TuButtonSize.xlarge ||
    TuButtonSize.large ||
    TuButtonSize.medium => styles.title[4],
    TuButtonSize.small => styles.title[5],
    TuButtonSize.xsmall => styles.title[6],
  };

  double get iconHeight => switch (this) {
    TuButtonSize.xlarge || TuButtonSize.large => 40.aw,
    TuButtonSize.medium => 36.aw,
    TuButtonSize.small => 32.aw,
    TuButtonSize.xsmall => 28.aw,
  };

  double get fixedWidth => switch (this) {
    TuButtonSize.xlarge => 600.aw,
    TuButtonSize.large => 320.aw,
    TuButtonSize.medium ||
    TuButtonSize.small ||
    TuButtonSize.xsmall => 170.aw,
  };
}

class _TuButtonIcon extends StatelessWidget {
  const _TuButtonIcon({required this.icon, required this.height});

  final Widget icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FittedBox(fit: BoxFit.contain, child: icon),
    );
  }
}

class _ResolvedToneStyle {
  const _ResolvedToneStyle({
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
}
