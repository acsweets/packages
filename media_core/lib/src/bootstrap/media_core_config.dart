import 'package:flutter/widgets.dart';

import '../player/media_session.dart';
import './media_core_logger.dart';

/// Playback policy knobs for [MediaSession].
class MediaPlaybackPolicy {
  const MediaPlaybackPolicy({
    this.pauseWhenNotVisible = true,
  });

  /// When true, session pauses controllers that leave the viewport.
  final bool pauseWhenNotVisible;
}

/// One-shot host configuration. Call [configureMediaCore] from app bootstrap.
class MediaCoreConfig {
  const MediaCoreConfig({
    this.registerLogoutCleanup,
    this.placeholderBuilder,
    this.errorBuilder,
    this.logger,
    this.policy = const MediaPlaybackPolicy(),
  });

  /// Host registers a cleanup callback for user logout (account systems vary).
  final void Function(VoidCallback cleanup)? registerLogoutCleanup;

  final WidgetBuilder? placeholderBuilder;
  final WidgetBuilder? errorBuilder;
  final MediaCoreLogger? logger;
  final MediaPlaybackPolicy policy;
}

bool _configured = false;
MediaCoreConfig _config = const MediaCoreConfig();

MediaCoreConfig get mediaCoreConfig => _config;

/// Configure the package once at app start.
Future<void> configureMediaCore(MediaCoreConfig config) async {
  _config = config;
  if (config.logger != null) {
    mediaCoreLog = config.logger!;
  }

  final register = config.registerLogoutCleanup;
  if (register != null) {
    register(() {
      MediaSession.instance.handleLogout();
    });
  }

  _configured = true;
}

/// Whether [configureMediaCore] has been called (optional for basic use).
bool get isMediaCoreConfigured => _configured;
