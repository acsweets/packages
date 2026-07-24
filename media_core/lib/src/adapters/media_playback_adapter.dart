import '../model/media_playback_state.dart';
import '../model/media_result.dart';

/// Backend player adapter used by [MediaPlayerController].
abstract class MediaPlaybackAdapter {
  void Function(MediaPlaybackState state)? onPlaybackStateChanged;
  void Function(Duration position)? onPositionChanged;
  void Function(Duration duration)? onDurationChanged;

  Future<MediaResult<void>> play();
  Future<MediaResult<void>> pause();
  Future<MediaResult<void>> stop();
  Future<MediaResult<void>> seek(Duration position);
  Future<MediaResult<void>> setVolume(double volume);

  Duration get currentPosition;
  Duration get totalDuration;
  double get currentVolume;
  MediaPlaybackState get playbackState;

  Future<void> dispose();
}
