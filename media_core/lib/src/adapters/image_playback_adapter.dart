import 'dart:async';

import '../model/media_playback_state.dart';
import '../model/media_result.dart';
import './media_playback_adapter.dart';

/// No-op adapter for still images.
class ImagePlaybackAdapter extends MediaPlaybackAdapter {
  MediaPlaybackState _state = MediaPlaybackState.stopped;

  @override
  Future<MediaResult<void>> play() async {
    _state = MediaPlaybackState.playing;
    onPlaybackStateChanged?.call(MediaPlaybackState.playing);
    scheduleMicrotask(() {
      _state = MediaPlaybackState.stopped;
      onPlaybackStateChanged?.call(MediaPlaybackState.stopped);
    });
    return const MediaOk(null);
  }

  @override
  Future<MediaResult<void>> pause() async => const MediaOk(null);

  @override
  Future<MediaResult<void>> stop() async {
    _state = MediaPlaybackState.stopped;
    onPlaybackStateChanged?.call(MediaPlaybackState.stopped);
    return const MediaOk(null);
  }

  @override
  Future<MediaResult<void>> seek(Duration position) async => const MediaOk(null);

  @override
  Future<MediaResult<void>> setVolume(double volume) async => const MediaOk(null);

  @override
  Duration get currentPosition => Duration.zero;

  @override
  Duration get totalDuration => Duration.zero;

  @override
  double get currentVolume => 1.0;

  @override
  MediaPlaybackState get playbackState => _state;

  @override
  Future<void> dispose() async {}
}
