import '../model/media_kind.dart';
import '../model/media_ref.dart';

/// Variant selection helpers over [MediaVariant] / [MediaRef].
class MediaSelector {
  const MediaSelector._();

  static List<MediaVariant> ofKind(MediaRef ref, MediaKind kind) {
    return ref.effectiveVariants.where((v) => v.kind == kind).toList();
  }

  static MediaVariant? bestImage(
    MediaRef ref, {
    double? preferredWidth,
    double? preferredHeight,
    bool allowAnimated = true,
  }) {
    final images = ofKind(ref, MediaKind.image).where((v) {
      if (allowAnimated) return true;
      final frames = v.meta?.frames ?? 1;
      return frames <= 1;
    }).toList();
    if (images.isEmpty) return null;

    final targetW = (preferredWidth ?? 0).round();
    final targetH = (preferredHeight ?? 0).round();
    if (targetW <= 0 || targetH <= 0) {
      return images.first;
    }

    final notSmaller = images.where((v) {
      final w = v.meta?.width ?? 0;
      final h = v.meta?.height ?? 0;
      return w >= targetW && h >= targetH;
    }).toList();

    final pool = notSmaller.isNotEmpty ? notSmaller : images;
    pool.sort((a, b) {
      return _sizeDistance(
        width: a.meta?.width ?? targetW,
        height: a.meta?.height ?? targetH,
        targetWidth: targetW,
        targetHeight: targetH,
      ).compareTo(
        _sizeDistance(
          width: b.meta?.width ?? targetW,
          height: b.meta?.height ?? targetH,
          targetWidth: targetW,
          targetHeight: targetH,
        ),
      );
    });
    return pool.first;
  }

  static List<MediaVariant> playableVideos(
    MediaRef ref, {
    double? preferredWidth,
    double? preferredHeight,
  }) {
    final videos = [
      ...ofKind(ref, MediaKind.video),
      ...ofKind(ref, MediaKind.livePhoto),
    ];
    final targetW = (preferredWidth ?? 0).round();
    final targetH = (preferredHeight ?? 0).round();
    videos.sort((a, b) {
      if (targetW > 0 && targetH > 0) {
        final cmp = _sizeDistance(
          width: a.meta?.width ?? targetW,
          height: a.meta?.height ?? targetH,
          targetWidth: targetW,
          targetHeight: targetH,
        ).compareTo(
          _sizeDistance(
            width: b.meta?.width ?? targetW,
            height: b.meta?.height ?? targetH,
            targetWidth: targetW,
            targetHeight: targetH,
          ),
        );
        if (cmp != 0) return cmp;
      }
      final aArea = (a.meta?.width ?? 0) * (a.meta?.height ?? 0);
      final bArea = (b.meta?.width ?? 0) * (b.meta?.height ?? 0);
      return bArea.compareTo(aArea);
    });
    return videos;
  }

  static List<MediaVariant> playableAudio(
    MediaRef ref, {
    int? preferredBitrate,
  }) {
    final audios = ofKind(ref, MediaKind.audio);
    audios.sort((a, b) {
      if (preferredBitrate != null && preferredBitrate > 0) {
        final aBr = a.meta?.bitrate ?? 0;
        final bBr = b.meta?.bitrate ?? 0;
        final aHas = aBr > 0;
        final bHas = bBr > 0;
        if (aHas != bHas) return aHas ? -1 : 1;
        if (aHas && bHas) {
          final cmp = (aBr - preferredBitrate).abs().compareTo(
            (bBr - preferredBitrate).abs(),
          );
          if (cmp != 0) return cmp;
        }
      }
      return (b.meta?.bitrate ?? 0).compareTo(a.meta?.bitrate ?? 0);
    });
    return audios;
  }

  static List<MediaVariant> playableStreams(
    MediaRef ref, {
    int? preferredBandwidth,
  }) {
    final streams = ofKind(ref, MediaKind.stream);
    streams.sort((a, b) {
      final aBw = a.meta?.bandwidth ?? 0;
      final bBw = b.meta?.bandwidth ?? 0;
      if (preferredBandwidth != null && preferredBandwidth > 0) {
        final cmp = (aBw - preferredBandwidth).abs().compareTo(
          (bBw - preferredBandwidth).abs(),
        );
        if (cmp != 0) return cmp;
      }
      return bBw.compareTo(aBw);
    });
    return streams;
  }

  static int _sizeDistance({
    required int width,
    required int height,
    required int targetWidth,
    required int targetHeight,
  }) {
    final dw = width - targetWidth;
    final dh = height - targetHeight;
    return dw * dw + dh * dh;
  }
}
