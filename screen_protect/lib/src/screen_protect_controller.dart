import 'package:flutter/foundation.dart';

/// Simple [ValueNotifier]-based controller for screenshot protection state.
///
/// - `true`  → protection **on** (screenshots blocked)
/// - `false` → protection **off** (whitelist / allow screenshots)
///
/// Defaults to `true` (secure by default). Host apps own whitelist logic and
/// call [setEnabled] when the allow-list status is known.
class ScreenProtectController extends ValueNotifier<bool> {
  ScreenProtectController({bool enabled = true}) : super(enabled);

  /// Whether screenshot protection is currently active.
  bool get isProtectionEnabled => value;

  /// Enable or disable screenshot protection.
  void setEnabled(bool enabled) {
    if (value == enabled) return;
    value = enabled;
  }

  /// Turn protection on (block screenshots).
  void enable() => setEnabled(true);

  /// Turn protection off (allow screenshots).
  void disable() => setEnabled(false);
}
