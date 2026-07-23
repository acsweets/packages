# screen_protect

Flutter screenshot / screen-recording protection with optional background blur.

Built on top of [`no_screenshot`](https://pub.dev/packages/no_screenshot). Designed to be dropped into any Flutter app without GetX / project-specific services.

## Features

| Feature | Android | iOS |
|---------|---------|-----|
| Block screenshots | `FLAG_SECURE` (black image) | Secure text-field trick |
| Screenshot detection | Yes | Yes |
| Best-effort file delete | Yes | Yes |
| Tip page after screenshot | Not needed | Use `ScreenProtectPage` |
| Background blur (app switcher) | Yes | Yes |
| Whitelist / disable callback | Yes | Yes |

## Install

```yaml
dependencies:
  screen_protect:
    git:
      url: git@github.com:acsweets/packages.git
      path: screen_protect
```

Or path dependency for local development:

```yaml
dependencies:
  screen_protect:
    path: packages/screen_protect
```

## Quick start

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_protect/screen_protect.dart';

final protectController = ScreenProtectController(); // default: enabled

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenProtect(
      controller: protectController,
      onScreenshot: (snapshot) {
        // iOS: show tip page. Android is already blacked out by FLAG_SECURE.
        if (Platform.isIOS) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const ScreenProtectPage()),
          );
        }
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const HomePage(),
      ),
    );
  }
}
```

### Whitelist (allow screenshots for some users)

```dart
// After login / config sync:
protectController.setEnabled(!user.isScreenCaptureEnabled);

// Or async check per apply:
ScreenProtect(
  isDisabled: () async => await api.isWhitelisted(),
  child: child,
);
```

### Protect only a subtree

```dart
ScreenProtect(
  useVisibilityDetector: true,
  child: SensitivePage(),
);
```

## API notes

- `screenshotOff()` = **block** screenshots
- `screenshotOn()` = **allow** screenshots
- Default is secure: protection **on** until the host disables it
- Background blur follows the enabled state (whitelist users skip blur too when protection is off)
- File deletion is best-effort; paths from the plugin may be placeholders

## Known limits

- iOS blocking depends on the underlying plugin / OS version
- iOS screen-recording blocking is limited
- System-level snapshots (e.g. debugger) cannot be fully prevented

## License

See [LICENSE](LICENSE).
