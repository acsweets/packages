# acsweets/packages

Personal Flutter / Dart package monorepo.

## Packages

| Package | Description |
|---------|-------------|
| [`screen_protect`](./screen_protect) | Screenshot / screen-recording protection + background blur |
| [`media_core`](./media_core) | Media cache and playback core (URL / local path / MediaRef) |
| [`token_ui`](./token_ui) | Token-driven Flutter UI kit with overridable theme |

## Use a package

```yaml
dependencies:
  screen_protect:
    git:
      url: git@github.com:acsweets/packages.git
      path: screen_protect

  media_core:
    git:
      url: git@github.com:acsweets/packages.git
      path: media_core

  token_ui:
    git:
      url: git@github.com:acsweets/packages.git
      path: token_ui
```

## Develop

```bash
cd screen_protect   # or media_core / token_ui
flutter pub get
flutter test
flutter analyze
```
