import 'dart:async';

import 'package:fvp/fvp.dart' as fvp;
import 'package:video_player/video_player.dart';

import '../bootstrap/media_core_logger.dart';
import '../cache/media_cache.dart';
import '../model/media_kind.dart';
import '../model/media_playback_state.dart';
import '../model/media_ref.dart';
import '../model/media_result.dart';
import './media_playback_adapter.dart';

/// Video adapter using [VideoPlayerController] + fvp.
class VideoPlaybackAdapter extends MediaPlaybackAdapter {
  VideoPlaybackAdapter({required this.variants});

  /// Ordered candidates (file-backed video or network stream).
  final List<MediaVariant> variants;

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;

  MediaPlaybackState _state = MediaPlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _volume = 1.0;

  static bool _fvpRegistered = false;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration get totalDuration => _totalDuration;

  @override
  double get currentVolume => _volume;

  @override
  MediaPlaybackState get playbackState => _state;

  VideoPlayerController? get videoPlayerController => _controller;

  @override
  Future<MediaResult<void>> play() async {
    if (_isDisposed) {
      return MediaErr(Exception('Adapter disposed'));
    }

    try {
      if (_state == MediaPlaybackState.paused && _isInitialized) {
        await _controller?.play();
        _updateState(MediaPlaybackState.playing);
        return const MediaOk(null);
      }

      _registerFvp();
      _updateState(MediaPlaybackState.buffering);

      final initialized = await _initWithVariants();
      if (!initialized) {
        _updateState(MediaPlaybackState.error);
        return MediaErr(Exception('No playable video variant'));
      }

      await _controller?.setVolume(_volume);
      await applyPlaybackConfig();
      await _controller?.play();
      _updateState(MediaPlaybackState.playing);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('VideoPlaybackAdapter: play failed', e, stackTrace);
      _updateState(MediaPlaybackState.error);
      return MediaErr(Exception('Video play failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> pause() async {
    if (_state != MediaPlaybackState.playing &&
        _state != MediaPlaybackState.buffering) {
      return const MediaOk(null);
    }
    try {
      await _controller?.pause();
      _updateState(MediaPlaybackState.paused);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('VideoPlaybackAdapter: pause failed', e, stackTrace);
      return MediaErr(Exception('Video pause failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> stop() async {
    if (_state == MediaPlaybackState.stopped) {
      return const MediaOk(null);
    }
    try {
      await _controller?.pause();
      await _controller?.seekTo(Duration.zero);
      _currentPosition = Duration.zero;
      onPositionChanged?.call(Duration.zero);
      _updateState(MediaPlaybackState.stopped);
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('VideoPlaybackAdapter: stop failed', e, stackTrace);
      _currentPosition = Duration.zero;
      _updateState(MediaPlaybackState.stopped);
      return MediaErr(Exception('Video stop failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> seek(Duration position) async {
    try {
      final clamped =
          position > _totalDuration && _totalDuration > Duration.zero
          ? _totalDuration
          : position;

      if (_controller != null && _isInitialized) {
        await _controller!.seekTo(clamped);
      }
      _currentPosition = clamped;
      onPositionChanged?.call(clamped);
      if (_state == MediaPlaybackState.stopped && _isInitialized) {
        _updateState(MediaPlaybackState.paused);
      }
      return const MediaOk(null);
    } catch (e, stackTrace) {
      mediaCoreLog.e('VideoPlaybackAdapter: seek failed', e, stackTrace);
      return MediaErr(Exception('Video seek failed: $e'));
    }
  }

  @override
  Future<MediaResult<void>> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _controller?.setVolume(_volume);
    } catch (e) {
      mediaCoreLog.w('VideoPlaybackAdapter: setVolume failed: $e');
    }
    return const MediaOk(null);
  }

  @override
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _controller?.removeListener(_onVideoStateChanged);
    try {
      await _controller?.dispose();
    } catch (e, stackTrace) {
      mediaCoreLog.e('VideoPlaybackAdapter: dispose failed', e, stackTrace);
    }
    _controller = null;
    _isInitialized = false;
  }

  void _registerFvp() {
    if (!_fvpRegistered) {
      fvp.registerWith();
      _fvpRegistered = true;
    }
  }

  Future<bool> _initWithVariants() async {
    for (final variant in variants) {
      try {
        final controller = await _buildController(variant);
        if (controller == null) continue;

        await controller.initialize();
        if (_isDisposed) {
          await controller.dispose();
          return false;
        }

        _controller = controller;
        _isInitialized = true;
        _totalDuration = controller.value.duration;
        onDurationChanged?.call(_totalDuration);
        controller.addListener(_onVideoStateChanged);
        mediaCoreLog.d(
          'VideoPlaybackAdapter: ready url=${variant.url} '
          'kind=${variant.kind} duration=$_totalDuration',
        );
        return true;
      } catch (e) {
        mediaCoreLog.w(
          'VideoPlaybackAdapter: init failed url=${variant.url}: $e',
        );
      }
    }
    return false;
  }

  Future<VideoPlayerController?> _buildController(MediaVariant variant) async {
    final options = VideoPlayerOptions(allowBackgroundPlayback: true);
    return switch (variant.kind) {
      MediaKind.stream => VideoPlayerController.networkUrl(
        Uri.parse(variant.url),
        videoPlayerOptions: options,
      ),
      MediaKind.video || MediaKind.livePhoto => () async {
        final file = await MediaCache.instance.getFile(
          variant.url,
          variant.kind == MediaKind.livePhoto
              ? MediaKind.video
              : variant.kind,
        );
        return VideoPlayerController.file(file, videoPlayerOptions: options);
      }(),
      _ => null,
    };
  }

  void _onVideoStateChanged() {
    final value = _controller?.value;
    if (value == null) return;

    if (value.position != _currentPosition) {
      _currentPosition = value.position;
      onPositionChanged?.call(value.position);
    }

    if (value.isBuffering && _state == MediaPlaybackState.playing) {
      _updateState(MediaPlaybackState.buffering);
    } else if (!value.isBuffering &&
        _state == MediaPlaybackState.buffering &&
        value.isPlaying) {
      _updateState(MediaPlaybackState.playing);
    }

    if (value.isCompleted) {
      _currentPosition = Duration.zero;
      onPositionChanged?.call(Duration.zero);
      _updateState(MediaPlaybackState.stopped);
    }

    if (value.hasError) {
      mediaCoreLog.e(
        'VideoPlaybackAdapter: error ${value.errorDescription}',
      );
      _updateState(MediaPlaybackState.error);
    }
  }

  void _updateState(MediaPlaybackState state) {
    if (_state == state) return;
    _state = state;
    onPlaybackStateChanged?.call(state);
  }

  /// Hook for subclasses (e.g. live photo mute + loop).
  Future<void> applyPlaybackConfig() async {}
}
