/// Flutter screenshot / screen-recording protection.
///
/// Typical usage — wrap the whole app:
/// ```dart
/// ScreenProtect(
///   enabledListenable: controller,
///   onScreenshot: (snapshot) {
///     // e.g. push a tip page on iOS
///   },
///   child: MaterialApp(...),
/// )
/// ```
library;

export 'package:no_screenshot/screenshot_snapshot.dart';

export 'src/screen_protect.dart';
export 'src/screen_protect_controller.dart';
export 'src/screen_protect_page.dart';
