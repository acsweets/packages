import '../bootstrap/media_core_config.dart';
import '../bootstrap/media_core_logger.dart';
import '../cache/media_cache.dart';
import '../model/media_kind.dart';
import '../model/media_playback_state.dart';
import './media_player_controller.dart';

/// Global coordination: playback mutex + logout cleanup.
///
/// LivePhoto list autoplay queue is intentionally **not** implemented.
class MediaSession {
  MediaSession._();

  static final MediaSession instance = MediaSession._();

  final _playerControllers = <MediaPlayerController>[];

  void registerPlayerController(MediaPlayerController controller) {
    _playerControllers.add(controller);
    mediaCoreLog.d(
      'MediaSession: register controller kind=${controller.kind}',
    );
  }

  void unregisterPlayerController(MediaPlayerController controller) {
    _playerControllers.remove(controller);
    mediaCoreLog.d('MediaSession: unregister controller');
  }

  /// Enforce mutex before a controller starts playing.
  Future<void> requestPlayback(MediaPlayerController controller) async {
    switch (controller.kind) {
      case MediaKind.audio:
        await _stopOthers(controller, {MediaKind.audio});
        break;
      case MediaKind.video:
      case MediaKind.livePhoto:
      case MediaKind.stream:
        await _stopOthers(controller, {
          MediaKind.video,
          MediaKind.livePhoto,
          MediaKind.stream,
        });
        break;
      case MediaKind.image:
      case MediaKind.coverImage:
      case MediaKind.previewImage:
      case MediaKind.unknown:
        break;
    }
  }

  void notifyPlaybackStopped(MediaPlayerController controller) {
    // Hook for future system media-session / audio_service integration.
    mediaCoreLog.d(
      'MediaSession: playback stopped kind=${controller.kind}',
    );
  }

  /// Pause controllers that left the viewport (host drives visibility).
  Future<void> onVisibilityChanged(
    MediaPlayerController controller, {
    required bool visible,
  }) async {
    if (!mediaCoreConfig.policy.pauseWhenNotVisible) return;

    if (!visible) {
      if (controller.playbackState.value == MediaPlaybackState.playing ||
          controller.playbackState.value == MediaPlaybackState.buffering) {
        controller.isVisibilityPaused = true;
        await controller.pause();
      }
      return;
    }

    if (controller.isVisibilityPaused) {
      controller.isVisibilityPaused = false;
      await controller.play();
    }
  }

  /// Host logout: stop players and cancel downloads.
  void handleLogout() {
    for (final controller in List.of(_playerControllers)) {
      controller.forceStop();
    }
    MediaCache.instance.cancelAllDownloads();
    mediaCoreLog.d('MediaSession: logout cleanup done');
  }

  Future<void> _stopOthers(
    MediaPlayerController requesting,
    Set<MediaKind> kinds,
  ) async {
    for (final controller in List.of(_playerControllers)) {
      if (identical(controller, requesting)) continue;
      if (!kinds.contains(controller.kind)) continue;
      if (controller.playbackState.value == MediaPlaybackState.stopped) {
        continue;
      }
      await controller.forceStop();
    }
  }
}
