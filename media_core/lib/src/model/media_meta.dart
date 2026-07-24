/// Optional display / selection metadata for a media resource.
class MediaMeta {
  const MediaMeta({
    this.width,
    this.height,
    this.duration,
    this.title,
    this.artist,
    this.frames,
    this.bitrate,
    this.bandwidth,
  });

  final int? width;
  final int? height;
  final Duration? duration;
  final String? title;
  final String? artist;

  /// Animated frame count; `<= 1` treated as static image.
  final int? frames;

  /// Preferred for audio variant selection.
  final int? bitrate;

  /// Preferred for stream variant selection.
  final int? bandwidth;
}
