import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

class TuBottomSheet extends StatefulWidget {
  const TuBottomSheet({
    super.key,
    required this.child,
    this.height,
    this.backgroundColor,
    this.borderRadius,
    this.onDismissing,
    this.onDismissed,
  });

  final Widget child;
  final double? height;
  final Color? backgroundColor;
  final double? borderRadius;

  /// Return `true` to allow dismiss, `false` to keep open.
  final Future<bool> Function()? onDismissing;
  final Future<void> Function()? onDismissed;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double? height,
    Color? backgroundColor,
    double? borderRadius,
    bool isDismissible = true,
    bool enableDrag = true,
    Future<bool> Function()? onDismissing,
    Future<void> Function()? onDismissed,
  }) async {
    final result = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      builder: (context) => TuBottomSheet(
        height: height,
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        onDismissing: onDismissing,
        onDismissed: onDismissed,
        child: child,
      ),
    );

    if (result == null && onDismissed != null) {
      await onDismissed();
    }

    return result;
  }

  @override
  State<TuBottomSheet> createState() => _TuBottomSheetState();
}

class _TuBottomSheetState extends State<TuBottomSheet> {
  bool _isHandlingDismiss = false;

  Future<void> _handleDismissAttempt() async {
    if (_isHandlingDismiss) {
      return;
    }

    final guard = widget.onDismissing;
    if (guard == null) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return;
    }

    _isHandlingDismiss = true;
    try {
      final shouldDismiss = await guard();
      if (!mounted || !shouldDismiss) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      _isHandlingDismiss = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = widget.borderRadius ?? 16.0;
    final defaultBackgroundColor =
        widget.backgroundColor ?? colors.bg.secondary;

    return PopScope(
      canPop: widget.onDismissing == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || widget.onDismissing == null) {
          return;
        }
        await _handleDismissAttempt();
      },
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: defaultBackgroundColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(defaultBorderRadius),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
