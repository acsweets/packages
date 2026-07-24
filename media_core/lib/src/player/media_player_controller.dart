import 'package:flutter/foundation.dart';

import '../adapters/audio_playback_adapter.dart';
import '../adapters/image_playback_adapter.dart';
import '../adapters/live_photo_playback_adapter.dart';
import '../adapters/media_playback_adapter.dart';
import '../adapters/video_playback_adapter.dart';
import '../bootstrap/media_core_logger.dart';
import '../model/media_kind.dart';
import '../model/media_playback_state.dart';
import '../model/media_ref.dart';
import '../model/media_result.dart';
import '../selection/media_selector.dart';
import './media_session.dart';

/// Controls playback for a single [MediaRef].
///
/// State is exposed via [ValueNotifier]s — no GetX.
class MediaPlayerController {
  MediaPlayerController({
    this.livePhotoMuted = false,
    this.livePhotoLooping = true,
  });

  final bool livePhotoMuted;
  final bool livePhotoLooping;

  MediaRef? _ref;
  bool _isBound = false;
  bool _isDisposed = false;
  MediaPlaybackAdapter? _adapter;

  final ValueNotifier<MediaPlaybackState> playbackState =
      ValueNotifier(MediaPlaybackState.stopped);
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> duration = ValueNotifier(Duration.zero);
  final ValueNotifier<double> volume = ValueNotifier(1.0);

  /// Set by [MediaSession] when paused due to visibility.
  bool isVisibilityPaused = false;

  MediaRef get ref {
    final value = _ref;
    if (value == null) {
      throw StateError('MediaPlayerController is not bound');
    }
    return value;
  }

  MediaKind get kind => ref.kind;

  VideoPlaybackAdapter? get videoAdapter {
    final adapter = _adapter;
    if (adapter is VideoPlaybackAdapter) return adapter;
    return null;
  }

  void bind(MediaRef media) {
    if (_isDisposed) {
      throw StateError('MediaPlayerController is disposed');
    }
    if (_ref != null) {
      if (_ref!.id != null &&
          media.id != null &&
          _ref!.id != media.id) {
        throw StateError(
          'Cannot rebind to a different media id: ${_ref!.id} → ${media.id}',
        );
      }
      return;
    }
    if (_isBound) {
      throw StateError('Controller already bound to a widget');
    }

    _ref = media;
    _isBound = true;
    _adapter = _createAdapter(media);
    _bindAdapterCallbacks();
    MediaSession.instance.registerPlayerController(this);
    mediaCoreLog.d('MediaPlayerController: bound kind=${media.kind}');
  }

  void unbind() {
    _isBound = false;
  }

  Future<MediaResult<void>> play() async {
    if (_isDisposed) return MediaErr(Exception('Controller disposed'));
    if (_ref == null || _adapter == null) {
      return MediaErr(Exception('Controller not bound'));
    }
    await MediaSession.instance.requestPlayback(this);
    isVisibilityPaused = false;
    return _adapter!.play();
  }

  Future<MediaResult<void>> pause() async {
    if (_isDisposed) return MediaErr(Exception('Controller disposed'));
    if (playbackState.value != MediaPlaybackState.playing &&
        playbackState.value != MediaPlaybackState.buffering) {
      return const MediaOk(null);
    }
    return _adapter?.pause() ?? const MediaOk(null);
  }

  Future<MediaResult<void>> stop() async {
    if (_isDisposed) return MediaErr(Exception('Controller disposed'));
    if (playbackState.value == MediaPlaybackState.stopped) {
      return const MediaOk(null);
    }
    final adapter = _adapter;
    if (adapter == null) {
      return const MediaOk(null);
    }
    final result = await adapter.stop();
    MediaSession.instance.notifyPlaybackStopped(this);
    return result;
  }

  /// Force stop used by session mutex (ignores user pause semantics).
  Future<void> forceStop() async {
    final adapter = _adapter;
    if (adapter != null) {
      await adapter.stop();
    }
    MediaSession.instance.notifyPlaybackStopped(this);
  }

  Future<MediaResult<void>> seek(Duration position) async {
    if (_isDisposed) return MediaErr(Exception('Controller disposed'));
    if (_adapter == null) return MediaErr(Exception('Controller not bound'));
    return _adapter!.seek(position);
  }

  Future<MediaResult<void>> setVolume(double value) async {
    if (_isDisposed) return MediaErr(Exception('Controller disposed'));
    volume.value = value.clamp(0.0, 1.0);
    return _adapter?.setVolume(volume.value) ?? const MediaOk(null);
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    MediaSession.instance.unregisterPlayerController(this);
    await _adapter?.dispose();
    _adapter = null;
    playbackState.dispose();
    position.dispose();
    duration.dispose();
    volume.dispose();
  }

  MediaPlaybackAdapter _createAdapter(MediaRef media) {
    switch (media.kind) {
      case MediaKind.image:
        return ImagePlaybackAdapter();
      case MediaKind.audio:
        return AudioPlaybackAdapter(
          variants: MediaSelector.playableAudio(media),
        );
      case MediaKind.video:
        final videos = MediaSelector.playableVideos(media);
        final streams = MediaSelector.playableStreams(media);
        return VideoPlaybackAdapter(variants: [...videos, ...streams]);
      case MediaKind.livePhoto:
        final videos = MediaSelector.playableVideos(media);
        return LivePhotoPlaybackAdapter(
          variants: videos.isNotEmpty
              ? videos
              : media.effectiveVariants,
          muted: livePhotoMuted,
          looping: livePhotoLooping,
        );
      case MediaKind.stream:
        return VideoPlaybackAdapter(
          variants: MediaSelector.playableStreams(media),
        );
      case MediaKind.coverImage:
      case MediaKind.previewImage:
      case MediaKind.unknown:
        return ImagePlaybackAdapter();
    }
  }

  void _bindAdapterCallbacks() {
    final adapter = _adapter;
    if (adapter == null) return;
    adapter.onPlaybackStateChanged = (state) {
      playbackState.value = state;
      if (state == MediaPlaybackState.stopped) {
        MediaSession.instance.notifyPlaybackStopped(this);
      }
    };
    adapter.onPositionChanged = (value) {
      position.value = value;
    };
    adapter.onDurationChanged = (value) {
      duration.value = value;
    };
  }
}
