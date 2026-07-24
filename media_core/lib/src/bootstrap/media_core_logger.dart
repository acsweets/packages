/// Injectable logger bridge. Default uses `dart:developer`.
abstract class MediaCoreLogger {
  void d(String message);
  void w(String message);
  void e(String message, [Object? error, StackTrace? stackTrace]);
}

/// Default logger via `dart:developer`.
class DeveloperMediaCoreLogger implements MediaCoreLogger {
  const DeveloperMediaCoreLogger();

  @override
  void d(String message) {
    // ignore: avoid_print — package default; hosts should inject their logger.
    assert(() {
      // Prefer developer.log in debug; print is fine for example apps.
      return true;
    }());
    // ignore: avoid_print
    print('[media_core] $message');
  }

  @override
  void w(String message) {
    // ignore: avoid_print
    print('[media_core][W] $message');
  }

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) {
    // ignore: avoid_print
    print('[media_core][E] $message ${error ?? ''}');
    if (stackTrace != null) {
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}

MediaCoreLogger mediaCoreLog = const DeveloperMediaCoreLogger();
