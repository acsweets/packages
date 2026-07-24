import 'media_kind.dart';
import 'media_meta.dart';

/// One concrete URL candidate (e.g. a resolution or bitrate).
class MediaVariant {
  const MediaVariant({
    required this.url,
    required this.kind,
    this.meta,
  });

  final String url;
  final MediaKind kind;
  final MediaMeta? meta;
}

/// Backend-agnostic media descriptor. Host maps any model → [MediaRef].
class MediaRef {
  const MediaRef({
    required this.url,
    required this.kind,
    this.id,
    this.coverUrl,
    this.meta,
    this.variants,
  });

  /// Optional host id (mutex / logging only; not required).
  final String? id;

  /// Primary resource URL, or local absolute path (starts with `/`).
  final String url;

  final MediaKind kind;

  /// Cover / first-frame URL (audio, video, livePhoto).
  final String? coverUrl;

  final MediaMeta? meta;

  /// Extra candidates for selection; when null, [url]+[kind] is the only one.
  final List<MediaVariant>? variants;

  factory MediaRef.image(
    String url, {
    String? id,
    MediaMeta? meta,
    List<MediaVariant>? variants,
  }) {
    return MediaRef(
      id: id,
      url: url,
      kind: MediaKind.image,
      meta: meta,
      variants: variants,
    );
  }

  factory MediaRef.video(
    String url, {
    String? id,
    String? coverUrl,
    MediaMeta? meta,
    List<MediaVariant>? variants,
  }) {
    return MediaRef(
      id: id,
      url: url,
      kind: MediaKind.video,
      coverUrl: coverUrl,
      meta: meta,
      variants: variants,
    );
  }

  factory MediaRef.audio(
    String url, {
    String? id,
    String? coverUrl,
    MediaMeta? meta,
    List<MediaVariant>? variants,
  }) {
    return MediaRef(
      id: id,
      url: url,
      kind: MediaKind.audio,
      coverUrl: coverUrl,
      meta: meta,
      variants: variants,
    );
  }

  factory MediaRef.livePhoto(
    String videoUrl, {
    String? id,
    required String coverUrl,
    MediaMeta? meta,
    List<MediaVariant>? variants,
  }) {
    return MediaRef(
      id: id,
      url: videoUrl,
      kind: MediaKind.livePhoto,
      coverUrl: coverUrl,
      meta: meta,
      variants: variants,
    );
  }

  /// Effective candidates: [variants] if non-empty, else a single primary.
  List<MediaVariant> get effectiveVariants {
    final list = variants;
    if (list != null && list.isNotEmpty) {
      return list;
    }
    return [MediaVariant(url: url, kind: kind, meta: meta)];
  }
}
