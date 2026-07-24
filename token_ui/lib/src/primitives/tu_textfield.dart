import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Token UI text field. Prefer [TuTextField.primary] / [TuTextField.search].
class TuTextField extends StatelessWidget {
  const TuTextField({
    super.key,
    this.tone,
    this.controller,
    this.focusNode,
    this.startIcon,
    this.iconSpacing,
    this.hintText,
    this.textStyle,
    this.hintStyle,
    this.contentPadding,
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.width,
    this.height,
    this.minHeight,
    this.maxHeight,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.isDisabled = false,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
  });

  factory TuTextField.primary({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    Widget? startIcon,
    String? hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    bool isDisabled = false,
    bool autofocus = false,
    double? width,
    int? maxLines = 1,
    int? minLines,
    int? maxLength,
    TextAlign textAlign = TextAlign.start,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
  }) {
    return TuTextField(
      key: key,
      tone: TuTextFieldTone.primary,
      controller: controller,
      focusNode: focusNode,
      startIcon: startIcon,
      hintText: hintText,
      width: width,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      isDisabled: isDisabled,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textAlign: textAlign,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
    );
  }

  /// Search field. Inject [searchIcon] or default [Icons.search].
  factory TuTextField.search({
    Key? key,
    TextEditingController? controller,
    FocusNode? focusNode,
    Widget? searchIcon,
    String? hintText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
  }) {
    return TuTextField(
      key: key,
      tone: TuTextFieldTone.search,
      controller: controller,
      focusNode: focusNode,
      startIcon: searchIcon,
      hintText: hintText,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
    );
  }

  final TuTextFieldTone? tone;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Widget? startIcon;
  final double? iconSpacing;
  final String? hintText;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final double? minHeight;
  final double? maxHeight;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool isDisabled;
  final bool autofocus;
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.styles;

    final toneStartIcon = switch (tone) {
      TuTextFieldTone.search => Icon(
        Icons.search,
        size: 32.aw,
        color: colors.text.placeholder,
      ),
      _ => null,
    };

    final toneIconSpacing = switch (tone) {
      TuTextFieldTone.primary || TuTextFieldTone.search => 16.aw,
      _ => null,
    };

    final toneHintText = switch (tone) {
      TuTextFieldTone.search => 'Search',
      _ => null,
    };

    final toneContentPadding = switch (tone) {
      TuTextFieldTone.primary => EdgeInsets.all(24.aw),
      TuTextFieldTone.search => EdgeInsets.symmetric(horizontal: 28.aw),
      _ => null,
    };

    final toneBorderRadius = switch (tone) {
      TuTextFieldTone.primary => BorderRadius.circular(20.aw),
      TuTextFieldTone.search => BorderRadius.circular(999999),
      _ => null,
    };

    final toneBorderWidth = switch (tone) {
      TuTextFieldTone.primary => 0.0,
      _ => null,
    };

    final toneHeight = switch (tone) {
      TuTextFieldTone.search => 64.aw,
      _ => null,
    };

    final toneHintColor = switch (tone) {
      TuTextFieldTone.search => colors.text.placeholder,
      TuTextFieldTone.primary => colors.text.secondary1,
      _ => null,
    };

    final toneBackgroundColor = switch (tone) {
      TuTextFieldTone.primary => colors.button.secondary,
      TuTextFieldTone.search => colors.bg.secondary,
      _ => null,
    };

    final effectiveStartIcon = startIcon ?? toneStartIcon;
    final effectiveIconSpacing = iconSpacing ?? toneIconSpacing;
    final effectiveHintText = hintText ?? toneHintText;
    final effectiveContentPadding = contentPadding ?? toneContentPadding;
    final effectiveBorderRadius = borderRadius ?? toneBorderRadius;
    final effectiveBorderWidth = borderWidth ?? toneBorderWidth;
    final effectiveHeight = height ?? toneHeight;

    final borderSide = switch ((effectiveBorderWidth, borderColor)) {
      (final width?, final color?) when width > 0 => BorderSide(
        color: color,
        width: width,
      ),
      _ => BorderSide.none,
    };

    Widget child = TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      enabled: !isDisabled,
      style: textStyle ?? styles.body[2],
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textAlign: textAlign,
      decoration: InputDecoration(
        hintText: effectiveHintText,
        hintStyle: hintStyle ?? (styles.body[2] + toneHintColor),
        border: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        isCollapsed: true,
        contentPadding: EdgeInsets.zero,
      ),
      cursorColor: textStyle?.color ?? colors.text.primary,
    );

    if (effectiveStartIcon case final icon?) {
      child = Row(
        spacing: effectiveIconSpacing ?? 0,
        children: [
          icon,
          Expanded(child: child),
        ],
      );
    }

    child = Container(
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
        maxHeight: maxHeight ?? double.infinity,
      ).tighten(width: width, height: effectiveHeight),
      decoration: BoxDecoration(
        border: BoxBorder.fromBorderSide(borderSide),
        borderRadius: effectiveBorderRadius,
        color: fillColor ?? toneBackgroundColor,
      ),
      padding: effectiveContentPadding,
      child: child,
    );

    if (isDisabled) {
      child = Opacity(opacity: 0.5, child: child);
    }

    return child;
  }
}

enum TuTextFieldTone { primary, search }
