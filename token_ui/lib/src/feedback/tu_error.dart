import 'package:flutter/material.dart';

import '../primitives/tu_button.dart';
import '../theme/tu_extensions.dart';

/// Error placeholder with optional retry via [TuButton.neutral].
class TuError extends StatelessWidget {
  const TuError({
    super.key,
    required this.message,
    required this.icon,
    this.retryLabel,
    this.isRetrying,
    this.onRetry,
  });

  factory TuError.network({
    String message = 'Network connection failed',
    Widget? icon,
    String? retryLabel,
    bool? isRetrying,
    VoidCallback? onRetry,
  }) => TuError(
    message: message,
    icon:
        icon ??
        Icon(Icons.wifi_off_outlined, size: 87.aw),
    retryLabel: retryLabel ?? (onRetry != null ? 'Try again' : null),
    isRetrying: isRetrying,
    onRetry: onRetry,
  );

  final String message;
  final Widget icon;
  final String? retryLabel;
  final bool? isRetrying;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        SizedBox(height: 24.aw),
        Text(
          message,
          style: context.styles.body[3] + context.colors.text.secondary1,
        ),
        if (retryLabel case final label?) ...[
          SizedBox(height: 32.aw),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TuButton.neutral(
                onPressed: onRetry,
                label: label,
                isLoading: isRetrying,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
