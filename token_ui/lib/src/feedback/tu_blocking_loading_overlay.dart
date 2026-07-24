import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Global blocking loading overlay via [Overlay].
///
/// Bind a navigator key once, or call [show] with a [BuildContext].
class TuBlockingLoadingOverlay {
  TuBlockingLoadingOverlay._();

  static OverlayEntry? _overlayEntry;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Bind host navigator key for service-layer [show] without context.
  static void bind(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Show overlay. Prefer [context]; falls back to [bind]ed navigator.
  static void show([BuildContext? context]) {
    if (_overlayEntry != null) {
      return;
    }

    OverlayState? overlay;
    if (context != null) {
      overlay = Overlay.maybeOf(context, rootOverlay: true);
    }
    overlay ??= _navigatorKey?.currentState?.overlay;
    if (overlay == null) {
      return;
    }

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: Stack(
            children: [
              ModalBarrier(
                dismissible: false,
                color: context.colors.mask.primary,
              ),
              const Center(child: CircularProgressIndicator.adaptive()),
            ],
          ),
        );
      },
    );

    _overlayEntry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    final entry = _overlayEntry;
    if (entry == null) {
      return;
    }
    _overlayEntry = null;
    entry.remove();
  }
}
