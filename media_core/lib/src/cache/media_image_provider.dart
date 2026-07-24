import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';

import '../model/media_kind.dart';
import './media_cache.dart';

/// [ImageProvider] backed by [MediaCache] disk cache.
class MediaImageProvider extends CachedNetworkImageProvider {
  MediaImageProvider(
    super.url, {
    MediaKind resourceKind = MediaKind.image,
    super.scale,
  }) : super(
         cacheManager: MediaCache.instance.getCacheManagerForKind(resourceKind),
         cacheKey: MediaCache.instance.cacheKeyForUrl(url),
       );

  /// Convenience widget using the same cache managers.
  static Widget network(
    String url, {
    MediaKind resourceKind = MediaKind.image,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: MediaCache.instance.getCacheManagerForKind(resourceKind),
      cacheKey: MediaCache.instance.cacheKeyForUrl(url),
      fit: fit,
      width: width,
      height: height,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
