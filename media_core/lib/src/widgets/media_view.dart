import 'package:flutter/widgets.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../bootstrap/media_core_config.dart';
import '../cache/media_image_provider.dart';
import '../model/media_kind.dart';
import '../model/media_ref.dart';
import '../selection/media_selector.dart';

/// Static media display (image / cover). No GetX.
class MediaView extends StatelessWidget {
  const MediaView({
    super.key,
    required this.ref,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.preferredWidth,
    this.preferredHeight,
  });

  final MediaRef ref;
  final BoxFit fit;
  final double? width;
  final double? height;
  final double? preferredWidth;
  final double? preferredHeight;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveImageUrl();
    if (imageUrl == null || imageUrl.isEmpty) {
      return _error(context);
    }

    return MediaImageProvider.network(
      imageUrl,
      resourceKind: ref.kind == MediaKind.coverImage
          ? MediaKind.coverImage
          : MediaKind.image,
      fit: fit,
      width: width,
      height: height,
      placeholder: (context, _) => _placeholder(context),
      errorWidget: (context, _, __) => _error(context),
    );
  }

  String? _resolveImageUrl() {
    if (ref.kind == MediaKind.image ||
        ref.kind == MediaKind.coverImage ||
        ref.kind == MediaKind.previewImage) {
      final best = MediaSelector.bestImage(
        ref,
        preferredWidth: preferredWidth,
        preferredHeight: preferredHeight,
      );
      return best?.url ?? ref.url;
    }
    return ref.coverUrl ?? ref.url;
  }

  Widget _placeholder(BuildContext context) {
    final builder = mediaCoreConfig.placeholderBuilder;
    if (builder != null) return builder(context);
    return const ColoredBox(color: Color(0x11000000));
  }

  Widget _error(BuildContext context) {
    final builder = mediaCoreConfig.errorBuilder;
    if (builder != null) return builder(context);
    return const ColoredBox(color: Color(0x22FF0000));
  }
}

/// Wraps a child with visibility → [MediaSession.onVisibilityChanged].
class MediaVisibilityScope extends StatelessWidget {
  const MediaVisibilityScope({
    super.key,
    required this.controllerKey,
    required this.onVisibilityChanged,
    required this.child,
  });

  final Key controllerKey;
  final void Function(bool visible) onVisibilityChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: controllerKey,
      onVisibilityChanged: (info) {
        onVisibilityChanged(info.visibleFraction >= 1.0);
      },
      child: child,
    );
  }
}
