# acsweets/packages

Personal Flutter / Dart package monorepo.

## Packages

| Package | Description |
|---------|-------------|
| [`screen_protect`](./screen_protect) | Screenshot / screen-recording protection + background blur |

## Use a package

```yaml
dependencies:
  screen_protect:
    git:
      url: git@github.com:acsweets/packages.git
      path: screen_protect
```

## Develop

```bash
cd screen_protect
flutter pub get
flutter test
flutter analyze
```
