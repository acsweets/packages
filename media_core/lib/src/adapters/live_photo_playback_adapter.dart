import './video_playback_adapter.dart';

/// LivePhoto = short video with optional mute / loop.
///
/// List autoplay queue is **not** included (see package boundary).
class LivePhotoPlaybackAdapter extends VideoPlaybackAdapter {
  LivePhotoPlaybackAdapter({
    required super.variants,
    this.muted = false,
    this.looping = false,
  });

  final bool muted;
  final bool looping;

  @override
  Future<void> applyPlaybackConfig() async {
    if (muted) {
      await videoPlayerController?.setVolume(0.0);
    }
    if (looping) {
      await videoPlayerController?.setLooping(true);
    }
  }
}
