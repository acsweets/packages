import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'package:no_screenshot/screenshot_snapshot.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'screen_protect_controller.dart';

/// Called when a screenshot is detected while protection is active.
typedef ScreenshotCallback = void Function(ScreenshotSnapshot snapshot);

/// Async whitelist check. Return `true` to **disable** protection
/// (i.e. allow screenshots) for the current user/session.
typedef IsDisabledCallback = Future<bool> Function();

/// Global / subtree screenshot protection widget.
///
/// Responsibilities:
/// - Block screenshots via `no_screenshot`
///   (`screenshotOff()` = block, `screenshotOn()` = allow)
/// - Listen for screenshot events and optionally delete the file
/// - Optional background blur when the app goes inactive
/// - Optional [VisibilityDetector] for subtree-scoped protection
///
/// **Naming note:** `screenshotOff()` means "turn screenshot capability off"
/// (block). `screenshotOn()` means "allow screenshots".
class ScreenProtect extends StatefulWidget {
  const ScreenProtect({
    super.key,
    required this.child,
    this.controller,
    this.enabledListenable,
    this.enabled = true,
    this.isDisabled,
    this.onScreenshot,
    this.deleteScreenshotOnDetect = true,
    this.enableBackgroundBlur = true,
    this.blurOverlayBuilder,
    this.useVisibilityDetector = false,
    this.log,
  });

  /// App / subtree to protect.
  final Widget child;

  /// Preferred way to drive protection state from the host app.
  final ScreenProtectController? controller;

  /// Alternative to [controller]: any `ValueListenable<bool>` where
  /// `true` means protection is active.
  final ValueListenable<bool>? enabledListenable;

  /// Static fallback when neither [controller] nor [enabledListenable]
  /// is provided. Defaults to `true` (secure by default).
  final bool enabled;

  /// Optional async whitelist. Return `true` to skip protection.
  /// Evaluated when applying protection (visibility change / state change).
  final IsDisabledCallback? isDisabled;

  /// Fired when a screenshot is detected and protection is active.
  /// Host apps typically push an iOS tip page here.
  final ScreenshotCallback? onScreenshot;

  /// Best-effort delete of the screenshot file when a path is available.
  final bool deleteScreenshotOnDetect;

  /// Show a blur overlay when the app is inactive / paused / hidden.
  /// Independent of whitelist by default — blur follows [enabled] state.
  final bool enableBackgroundBlur;

  /// Custom blur overlay. Defaults to a dark blurred cover with a
  /// "Screen protection is on" label.
  final WidgetBuilder? blurOverlayBuilder;

  /// When `true`, enable/disable protection based on widget visibility
  /// (useful for protecting a specific page/subtree).
  /// When `false` (default), treat this as a global always-mounted wrapper.
  final bool useVisibilityDetector;

  /// Optional logger: `(level, message, [error])`.
  /// Levels: `i` / `w` / `e`.
  final void Function(String level, String message, [Object? error])? log;

  @override
  State<ScreenProtect> createState() => _ScreenProtectState();
}

class _ScreenProtectState extends State<ScreenProtect>
    with WidgetsBindingObserver {
  final _noScreenshot = NoScreenshot.instance;
  final _visibilityKey = UniqueKey();

  StreamSubscription<ScreenshotSnapshot>? _screenshotSub;
  ValueListenable<bool>? _boundListenable;
  bool _isInBackground = false;
  bool _isBlurVisible = false;
  bool _isVisible = true;

  ValueListenable<bool>? get _listenable =>
      widget.controller ?? widget.enabledListenable;

  bool get _protectionEnabled {
    final listenable = _listenable;
    if (listenable != null) return listenable.value;
    return widget.enabled;
  }

  void _log(String level, String message, [Object? error]) {
    widget.log?.call(level, message, error);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bindListenable();
    _setupScreenshotListener();
    if (!widget.useVisibilityDetector) {
      unawaited(_applyProtection());
    }
  }

  @override
  void didUpdateWidget(covariant ScreenProtect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.enabledListenable != widget.enabledListenable) {
      _unbindListenable();
      _bindListenable();
      unawaited(_applyProtection());
    } else if (oldWidget.enabled != widget.enabled && _listenable == null) {
      unawaited(_applyProtection());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unbindListenable();
    unawaited(_screenshotSub?.cancel() ?? Future<void>.value());
    // Best-effort: re-allow screenshots when this protector is removed.
    unawaited(_noScreenshot.screenshotOn());
    unawaited(_noScreenshot.stopScreenshotListening());
    super.dispose();
  }

  void _bindListenable() {
    _boundListenable = _listenable;
    _boundListenable?.addListener(_onEnabledChanged);
  }

  void _unbindListenable() {
    _boundListenable?.removeListener(_onEnabledChanged);
    _boundListenable = null;
  }

  void _onEnabledChanged() {
    unawaited(_applyProtection());
    if (mounted) setState(() {});
  }

  Future<void> _applyProtection() async {
    try {
      if (await _shouldSkipProtection()) {
        await _noScreenshot.screenshotOn();
        _log('i', 'ScreenProtect: protection skipped (whitelist / disabled)');
        return;
      }

      if (widget.useVisibilityDetector && !_isVisible) {
        await _noScreenshot.screenshotOn();
        await _noScreenshot.stopScreenshotListening();
        _log('i', 'ScreenProtect: not visible, protection off');
        return;
      }

      if (_protectionEnabled) {
        await _noScreenshot.screenshotOff();
        await _noScreenshot.startScreenshotListening();
        _log('i', 'ScreenProtect: protection enabled');
      } else {
        await _noScreenshot.screenshotOn();
        await _noScreenshot.stopScreenshotListening();
        _log('i', 'ScreenProtect: protection disabled');
      }
    } catch (e) {
      _log('e', 'ScreenProtect: failed to apply protection', e);
    }
  }

  Future<bool> _shouldSkipProtection() async {
    final callback = widget.isDisabled;
    if (callback == null) return false;
    try {
      return await callback();
    } catch (e) {
      _log('e', 'ScreenProtect: isDisabled callback failed, keep protection', e);
      return false;
    }
  }

  Future<void> _setupScreenshotListener() async {
    try {
      await _noScreenshot.startScreenshotListening();
      _screenshotSub = _noScreenshot.screenshotStream.listen(
        _handleScreenshotEvent,
      );
    } catch (e) {
      _log('e', 'ScreenProtect: failed to start screenshot listening', e);
    }
  }

  void _handleScreenshotEvent(ScreenshotSnapshot snapshot) {
    if (!snapshot.wasScreenshotTaken) return;
    if (!_protectionEnabled) return;

    _log('i', 'ScreenProtect: screenshot detected');

    if (widget.deleteScreenshotOnDetect) {
      unawaited(_tryDeleteScreenshot(snapshot.screenshotPath));
    }

    widget.onScreenshot?.call(snapshot);
  }

  Future<void> _tryDeleteScreenshot(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        _log('i', 'ScreenProtect: deleted screenshot file: $path');
      }
    } catch (e) {
      _log('w', 'ScreenProtect: failed to delete screenshot (permissions?)', e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.enableBackgroundBlur) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (!_isInBackground) {
          _isInBackground = true;
          setState(() => _isBlurVisible = true);
        }
      case AppLifecycleState.resumed:
        if (_isInBackground) {
          _isInBackground = false;
          setState(() => _isBlurVisible = false);
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final visible = info.visibleFraction > 0;
    if (visible == _isVisible) return;
    _isVisible = visible;
    unawaited(_applyProtection());
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (widget.useVisibilityDetector) {
      content = VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _onVisibilityChanged,
        child: content,
      );
    }

    final showBlur = widget.enableBackgroundBlur &&
        _isBlurVisible &&
        _protectionEnabled;

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          content,
          if (showBlur)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isInBackground ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: widget.blurOverlayBuilder?.call(context) ??
                    _DefaultBlurOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DefaultBlurOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.security, size: 64, color: Colors.white70),
              SizedBox(height: 16),
              Text(
                'Screen protection is on',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
