/// Cache / playback isolation dimension.
enum MediaKind {
  image,
  video,
  audio,
  stream,
  coverImage,
  previewImage,
  /// Cover + short looping video (thin video config). No list autoplay queue.
  livePhoto,
  unknown,
}
