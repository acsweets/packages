import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../bootstrap/media_core_logger.dart';
import '../model/media_kind.dart';
import '../model/media_ref.dart';

/// Disk cache for media URLs.
///
/// - One [CacheManager] per [MediaKind]
/// - SHA256(url) as cache key
/// - In-flight download dedupe + concurrency limit
///
/// Network fetch is performed by `flutter_cache_manager` against the URL.
/// Hosts obtain URLs from any repository / API; this class never imports them.
class MediaCache {
  MediaCache._();

  static final MediaCache instance = MediaCache._();

  factory MediaCache() => instance;

  final _pendingDownloads = <String, Future<File>>{};
  int maxConcurrentDownloads = 5;
  int _activeDownloads = 0;
  final _downloadQueue = <_DownloadTask>[];
  final _cacheManagers = <String, CacheManager>{};
  final _trackedCacheKeys = <MediaKind, Set<String>>{};

  /// Download (or return cached) file for [url] under [kind].
  Future<File> getFile(
    String url,
    MediaKind kind, {
    void Function(double progress)? onProgress,
  }) async {
    if (_isLocalAbsolutePath(url)) {
      return _openLocalFile(url);
    }

    final cacheKey = _buildCacheKey(url);
    final pendingKey = _buildPendingKey(kind, cacheKey);
    final cacheManager = _getCacheManager(kind);

    final pending = _pendingDownloads[pendingKey];
    if (pending != null) {
      return pending;
    }

    final cachedFile = await _getCachedFile(cacheManager, cacheKey);
    if (cachedFile != null) {
      _trackCacheKey(kind, cacheKey);
      return cachedFile;
    }

    final completer = Completer<File>();
    final task = _DownloadTask(
      url: url,
      cacheKey: cacheKey,
      resourceKind: kind,
      cacheManager: cacheManager,
      onProgress: onProgress,
      completer: completer,
    );

    _pendingDownloads[pendingKey] = completer.future;
    _downloadQueue.add(task);
    _processDownloadQueue();

    try {
      return await completer.future;
    } finally {
      _pendingDownloads.remove(pendingKey);
    }
  }

  /// Convenience: first effective variant of [ref].
  Future<File> getRef(
    MediaRef ref, {
    void Function(double progress)? onProgress,
  }) {
    final variant = ref.effectiveVariants.first;
    return getFile(variant.url, variant.kind, onProgress: onProgress);
  }

  Future<File?> getCachedFile(String url, MediaKind kind) async {
    if (_isLocalAbsolutePath(url)) {
      try {
        return await _openLocalFile(url);
      } catch (_) {
        return null;
      }
    }

    final cacheManager = _getCacheManager(kind);
    final cacheKey = _buildCacheKey(url);
    final file = await _getCachedFile(cacheManager, cacheKey);
    if (file != null) {
      _trackCacheKey(kind, cacheKey);
    }
    return file;
  }

  /// Generate (or return cached) JPEG preview for a video URL.
  Future<File?> getVideoPreviewFile(
    String videoUrl, {
    int maxWidth = 512,
    int quality = 75,
  }) async {
    final previewKey = _buildVideoPreviewCacheKey(
      videoUrl,
      maxWidth: maxWidth,
      quality: quality,
    );
    const previewType = MediaKind.previewImage;
    final previewManager = _getCacheManager(previewType);

    final cachedPreview = await _getCachedFile(previewManager, previewKey);
    if (cachedPreview != null) {
      _trackCacheKey(previewType, previewKey);
      return cachedPreview;
    }

    try {
      final sourceFile = await getFile(videoUrl, MediaKind.video);
      final thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: sourceFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxWidth,
        quality: quality,
      );

      if (thumbnailBytes == null || thumbnailBytes.isEmpty) {
        return null;
      }

      return _putPreviewFile(
        manager: previewManager,
        previewKey: previewKey,
        previewType: previewType,
        bytes: thumbnailBytes,
      );
    } catch (e, stackTrace) {
      mediaCoreLog.w('MediaCache: preview failed ($videoUrl): $e');
      mediaCoreLog.e('MediaCache: preview stack', e, stackTrace);
      return null;
    }
  }

  Future<void> cleanCache({Duration? olderThan}) async {
    if (olderThan == null) {
      await clearAllCache();
      return;
    }

    final cutoff = DateTime.now().subtract(olderThan);

    for (final entry in _trackedCacheKeys.entries) {
      final type = entry.key;
      final manager = _getCacheManager(type);
      final keys = entry.value.toList();

      for (final key in keys) {
        try {
          final fileInfo = await manager.getFileFromCache(key);
          if (fileInfo == null) {
            entry.value.remove(key);
            continue;
          }

          if (fileInfo.validTill.isBefore(cutoff)) {
            await manager.removeFile(key);
            entry.value.remove(key);
          }
        } catch (e) {
          mediaCoreLog.w('MediaCache: clean failed (type=$type, key=$key): $e');
        }
      }
    }
  }

  Future<void> clearAllCache() async {
    for (final manager in _cacheManagers.values) {
      await manager.emptyCache();
    }
    _trackedCacheKeys.clear();
  }

  Future<int> getCacheSize() async {
    var totalSize = 0;

    for (final entry in _trackedCacheKeys.entries) {
      final manager = _getCacheManager(entry.key);
      for (final key in entry.value) {
        try {
          final fileInfo = await manager.getFileFromCache(key);
          if (fileInfo != null && fileInfo.file.existsSync()) {
            totalSize += fileInfo.file.lengthSync();
          }
        } catch (e) {
          mediaCoreLog.w(
            'MediaCache: size failed (type=${entry.key}, key=$key): $e',
          );
        }
      }
    }

    return totalSize;
  }

  void cancelAllDownloads() {
    for (final task in _downloadQueue) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(Exception('Download cancelled'));
      }
    }
    _downloadQueue.clear();
    _pendingDownloads.clear();
  }

  /// Public cache key for a URL (SHA256). Used by [MediaImageProvider].
  String cacheKeyForUrl(String url) => _buildCacheKey(url);

  /// Underlying [CacheManager] for a [MediaKind] (shared with image widgets).
  CacheManager getCacheManagerForKind(MediaKind kind) => _getCacheManager(kind);

  String _hashUrl(String url) => sha256.convert(url.codeUnits).toString();

  String _buildCacheKey(String url) => _hashUrl(url);

  String _buildPendingKey(MediaKind kind, String cacheKey) =>
      '${kind.name}::$cacheKey';

  String _buildVideoPreviewCacheKey(
    String url, {
    required int maxWidth,
    required int quality,
  }) {
    return 'preview_${_hashUrl('$url::$maxWidth::$quality')}';
  }

  bool _isLocalAbsolutePath(String url) => url.startsWith('/');

  Future<File> _openLocalFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('Local file not found: $path');
    }
    RandomAccessFile? handle;
    try {
      handle = await file.open(mode: FileMode.read);
    } finally {
      await handle?.close();
    }
    return file;
  }

  String _resourceTypeKey(MediaKind kind) {
    return switch (kind) {
      MediaKind.image => 'image',
      MediaKind.video => 'video',
      MediaKind.audio => 'audio',
      MediaKind.stream => 'stream',
      MediaKind.coverImage => 'cover_image',
      MediaKind.previewImage => 'preview_image',
      MediaKind.livePhoto => 'live_photo',
      MediaKind.unknown => 'unknown',
    };
  }

  CacheManager _getCacheManager(MediaKind kind) {
    final typeName = _resourceTypeKey(kind);
    final key = 'media_core_$typeName';

    return _cacheManagers.putIfAbsent(key, () {
      return CacheManager(
        Config(
          key,
          maxNrOfCacheObjects: 500,
          stalePeriod: const Duration(days: 30),
        ),
      );
    });
  }

  Future<File?> _getCachedFile(CacheManager manager, String cacheKey) async {
    try {
      final fileInfo = await manager.getFileFromCache(cacheKey);
      if (fileInfo != null) {
        return fileInfo.file;
      }
    } catch (e) {
      mediaCoreLog.w('MediaCache: read cache failed: $e');
    }
    return null;
  }

  void _processDownloadQueue() {
    while (_activeDownloads < maxConcurrentDownloads &&
        _downloadQueue.isNotEmpty) {
      final task = _downloadQueue.removeAt(0);
      _activeDownloads++;
      _executeDownload(task);
    }
  }

  Future<void> _executeDownload(_DownloadTask task) async {
    try {
      final stream = task.cacheManager.getFileStream(
        task.url,
        key: task.cacheKey,
        withProgress: task.onProgress != null,
      );

      File? resultFile;

      await for (final response in stream) {
        if (response is DownloadProgress) {
          final progress = response.progress;
          if (progress != null) {
            task.onProgress?.call(progress);
          }
        } else if (response is FileInfo) {
          resultFile = response.file;
        }
      }

      if (resultFile != null && !task.completer.isCompleted) {
        _trackCacheKey(task.resourceKind, task.cacheKey);
        task.completer.complete(resultFile);
      } else if (!task.completer.isCompleted) {
        task.completer.completeError(
          Exception('Download finished without file: ${task.url}'),
        );
      }
    } catch (e) {
      if (!task.completer.isCompleted) {
        task.completer.completeError(e);
      }
    } finally {
      _activeDownloads--;
      _processDownloadQueue();
    }
  }

  void _trackCacheKey(MediaKind kind, String cacheKey) {
    _trackedCacheKeys.putIfAbsent(kind, () => <String>{}).add(cacheKey);
  }

  Future<File> _putPreviewFile({
    required CacheManager manager,
    required String previewKey,
    required MediaKind previewType,
    required Uint8List bytes,
  }) async {
    final file = await manager.putFile(
      previewKey,
      bytes,
      key: previewKey,
      fileExtension: 'jpg',
    );
    _trackCacheKey(previewType, previewKey);
    return file;
  }
}

class _DownloadTask {
  _DownloadTask({
    required this.url,
    required this.cacheKey,
    required this.resourceKind,
    required this.cacheManager,
    required this.completer,
    this.onProgress,
  });

  final String url;
  final String cacheKey;
  final MediaKind resourceKind;
  final CacheManager cacheManager;
  final void Function(double progress)? onProgress;
  final Completer<File> completer;
}
