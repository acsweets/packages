# screen_protect

Flutter 防截屏 / 防录屏组件包，带可选的多任务后台模糊保护。

基于 [`no_screenshot`](https://pub.dev/packages/no_screenshot) 封装，**不依赖 GetX / 业务 Service / 项目路由**，可直接接入任意 Flutter 工程。

---

## 功能一览

| 能力 | Android | iOS |
|------|---------|-----|
| 阻止截屏 | `FLAG_SECURE`（截出来是黑图） | Secure text field 技巧（截出来偏空白） |
| 截屏事件检测 | ✅ | ✅ |
| 尽力删除截屏文件 | ✅ | ✅ |
| 截屏后提示页 | 一般不需要 | 可用内置 `ScreenProtectPage` |
| 切到后台时模糊遮罩 | ✅ | ✅ |
| 白名单 / 动态开关 | ✅ | ✅ |
| 仅保护某个页面/子树 | ✅（`useVisibilityDetector`） | ✅ |

---

## 1. 如何引入

### 方式 A：Git 依赖（推荐，直接用远程仓库）

在业务工程的 `pubspec.yaml` 中加入：

```yaml
dependencies:
  flutter:
    sdk: flutter

  screen_protect:
    git:
      url: git@github.com:acsweets/packages.git
      path: screen_protect
      # 可选：锁定分支 / tag / commit，避免被 main 改动影响
      # ref: main
```

若本机更习惯 HTTPS：

```yaml
dependencies:
  screen_protect:
    git:
      url: https://github.com/acsweets/packages.git
      path: screen_protect
```

> 注意：本仓库是 **monorepo**，包在子目录 `screen_protect/` 下，所以必须写 `path: screen_protect`。

然后执行：

```bash
flutter pub get
```

### 方式 B：本地 path 依赖（开发联调）

如果已经把仓库 clone 到本地，或本工程旁有一份源码：

```yaml
dependencies:
  screen_protect:
    path: ../packages/screen_protect
    # 或：path: packages/screen_protect
```

```bash
flutter pub get
```

### 方式 C：同时存在多个包时的写法

本仓库后续若还有其他包，各自用不同 `path` 即可：

```yaml
dependencies:
  screen_protect:
    git:
      url: git@github.com:acsweets/packages.git
      path: screen_protect
```

---

## 2. 如何 import

业务代码里统一从包入口导入即可（不要直接 import `src/` 下的实现文件）：

```dart
import 'package:screen_protect/screen_protect.dart';
```

该入口会导出：

| 符号 | 说明 |
|------|------|
| `ScreenProtect` | 核心保护组件，一般包在 `MaterialApp` 外层 |
| `ScreenProtectController` | 开关控制器（`ValueNotifier<bool>`） |
| `ScreenProtectPage` | iOS 截屏提示页（可直接路由跳转） |
| `ScreenshotSnapshot` | 截屏事件信息（来自 `no_screenshot`） |
| `ScreenshotCallback` / `IsDisabledCallback` | 回调类型别名 |

---

## 3. 最小接入（全局保护整个 App）

推荐把 `ScreenProtect` 包在 `MaterialApp` / `MaterialApp.router` **外面**。

```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:screen_protect/screen_protect.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 默认开启保护（安全优先）。
final protectController = ScreenProtectController();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenProtect(
      controller: protectController,
      // 检测到截屏时回调（保护开启时才会触发）
      onScreenshot: (ScreenshotSnapshot snapshot) {
        // Android 已被 FLAG_SECURE 黑屏，一般不必弹提示
        // iOS 建议弹提示页
        if (Platform.isIOS) {
          navigatorKey.currentState?.push(
            MaterialPageRoute<void>(
              builder: (_) => const ScreenProtectPage(),
            ),
          );
        }
      },
      // 可选：对接项目日志
      log: (level, message, [error]) {
        debugPrint('[$level] $message ${error ?? ''}');
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const HomePage(),
      ),
    );
  }
}
```

用 GoRouter 时同理：

```dart
return ScreenProtect(
  controller: protectController,
  onScreenshot: (snapshot) {
    if (Platform.isIOS) {
      // 用你自己的 router / navigatorKey 跳到提示页
      router.push('/screen-protect');
    }
  },
  child: MaterialApp.router(
    routerConfig: router,
  ),
);
```

提示页路由示例：

```dart
GoRoute(
  path: '/screen-protect',
  builder: (context, state) => const ScreenProtectPage(),
),
```

---

## 4. 开关与白名单

### 4.1 用 Controller（推荐）

`true` = **开启保护（禁止截屏）**  
`false` = **关闭保护（允许截屏）**

```dart
// 登录后 / 拉完配置后：
protectController.setEnabled(true);   // 禁止截屏
protectController.setEnabled(false);  // 允许截屏（白名单）

// 语义糖：
protectController.enable();
protectController.disable();

// 读取当前状态：
final on = protectController.isProtectionEnabled;
```

示例：服务端字段 `isScreenCaptureEnabled == true` 表示允许截屏：

```dart
// 允许截屏 → 关闭保护
protectController.setEnabled(!user.isScreenCaptureEnabled);
```

### 4.2 用任意 `ValueListenable<bool>`

如果你已有自己的状态源（不强制用本包的 Controller）：

```dart
ScreenProtect(
  enabledListenable: myNotifier, // true = 保护开启
  child: child,
);
```

### 4.3 用静态 `enabled`

不需要动态切换时：

```dart
ScreenProtect(
  enabled: true, // 默认就是 true
  child: child,
);
```

### 4.4 用异步白名单回调 `isDisabled`

返回 `true` 表示 **跳过保护（允许截屏）**：

```dart
ScreenProtect(
  isDisabled: () async {
    final user = await api.fetchUser();
    return user.isScreenCaptureEnabled; // true = 白名单，不保护
  },
  child: child,
);
```

> 回调抛错时，包内会保守处理：**继续保护**。

---

## 5. 只保护某个页面 / 子树

全局包一层最省事；若只想保护敏感页，打开可见性检测：

```dart
class SensitivePage extends StatelessWidget {
  const SensitivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenProtect(
      useVisibilityDetector: true,
      onScreenshot: (snapshot) {
        if (Platform.isIOS) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ScreenProtectPage(),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Sensitive')),
        body: const Center(child: Text('Protected content')),
      ),
    );
  }
}
```

页面不可见时会自动 `screenshotOn()`，离开敏感页后恢复可截屏。

---

## 6. 自定义后台模糊层

默认是黑色半透明 + 高斯模糊 + `"Screen protection is on"`。

```dart
ScreenProtect(
  enableBackgroundBlur: true, // 默认 true；不需要可设 false
  blurOverlayBuilder: (context) {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: const Text(
        '内容已隐藏',
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  },
  child: child,
);
```

模糊层会在 App 进入 `inactive` / `paused` / `hidden` 时显示，`resumed` 时隐藏。  
**保护关闭（白名单）时不会显示模糊层。**

---

## 7. 自定义截屏提示页文案

```dart
const ScreenProtectPage(
  title: 'Screenshot Not Allowed',
  message:
      'This content is protected. Screenshots are not permitted to ensure content security.',
  buttonLabel: 'Got it',
);
```

或完全自己做页面，只在 `onScreenshot` 里跳转即可。

---

## 8. `ScreenProtect` 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `child` | `Widget` | 必填 | 被保护的子树 |
| `controller` | `ScreenProtectController?` | `null` | 推荐的动态开关 |
| `enabledListenable` | `ValueListenable<bool>?` | `null` | 自定义 Listenable，`true`=保护开 |
| `enabled` | `bool` | `true` | 无 Listenable 时的静态开关 |
| `isDisabled` | `Future<bool> Function()?` | `null` | 返回 `true` 则跳过保护 |
| `onScreenshot` | `void Function(ScreenshotSnapshot)?` | `null` | 检测到截屏时回调 |
| `deleteScreenshotOnDetect` | `bool` | `true` | 是否尽力删除截屏文件 |
| `enableBackgroundBlur` | `bool` | `true` | 是否启后台模糊 |
| `blurOverlayBuilder` | `WidgetBuilder?` | `null` | 自定义模糊层 |
| `useVisibilityDetector` | `bool` | `false` | `true` 时按可见性开关保护 |
| `log` | `Function?` | `null` | 日志回调：`(level, message, [error])` |

优先级（是否保护）：

1. 若 `isDisabled()` 返回 `true` → 不保护  
2. 否则看 `controller` / `enabledListenable` / `enabled`  
3. 若开了 `useVisibilityDetector` 且不可见 → 不保护  

---

## 9. 重要命名提醒

底层插件 API 容易看反：

| API | 实际含义 |
|-----|----------|
| `screenshotOff()` | **禁止**截屏（关闭截屏能力） |
| `screenshotOn()` | **允许**截屏 |

本包对外统一用「保护是否开启」语义：`isProtectionEnabled == true` 表示禁止截屏。

---

## 10. 平台差异（接入时心里有数）

| 行为 | Android | iOS |
|------|---------|-----|
| 阻止机制 | 系统 `FLAG_SECURE` | 插件 secure text field |
| 用户截到的内容 | 黑图 | 空白/无效内容 |
| 是否建议弹提示页 | 否 | 是 |
| 录屏 | 一般一并拦住 | 能力有限 |
| 删除相册里的截屏文件 | 尽力而为，路径可能是占位符 | 同左 |

---

## 11. 建议自测清单

1. Android：保护开着时截屏，应得到黑图  
2. iOS：保护开着时截屏，应进 `onScreenshot`，并可弹出 `ScreenProtectPage`  
3. `protectController.disable()` 后，两端应可正常截屏  
4. 切到多任务界面：保护开启时应看到模糊遮罩  
5. 白名单用户：截屏可用，且后台模糊不出现  

---

## 12. 已知限制

- iOS 阻止效果依赖 `no_screenshot` 与系统版本，部分版本可能削弱  
- 截屏文件删除是「尽力而为」，不能保证所有机型成功  
- 系统级快照（如调试器、部分系统截图通道）无法 100% 防御  
- iOS 录屏拦截能力有限  

---

## 开发与验证（包维护者）

```bash
cd screen_protect
flutter pub get
flutter test
flutter analyze
```

---

## License

见 [LICENSE](LICENSE)。
