import 'package:flutter/material.dart';

/// Default tip page shown after an iOS screenshot is detected.
///
/// Android usually does not need this page because `FLAG_SECURE` already
/// produces a black screenshot. Host apps decide when to push this route
/// (typically from [ScreenProtect.onScreenshot] when `Platform.isIOS`).
class ScreenProtectPage extends StatelessWidget {
  const ScreenProtectPage({
    super.key,
    this.title = 'Screenshot Not Allowed',
    this.message =
        'This content is protected. Screenshots are not permitted to ensure content security.',
    this.buttonLabel = 'Got it',
    this.onConfirm,
    this.icon = Icons.security,
  });

  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onConfirm;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(
                icon,
                size: 80,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onConfirm ?? () => Navigator.of(context).maybePop(),
                  child: Text(buttonLabel),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
