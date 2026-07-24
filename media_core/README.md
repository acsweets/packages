# media_core

跨项目可复用的 Flutter **媒体缓存与播放内核**。

宿主 App 用任意网络栈 / 仓库拿到资源 URL 后，构造 `MediaRef`（或直接传 URL）交给本包即可。  
本包**不绑定**任何业务 API（如 `nocnok_api`）、**不使用 GetX**、**不依赖主工程**。

---

## 目录

1. [它解决什么问题](#1-它解决什么问题)
2. [能力边界](#2-能力边界)
3. [安装](#3-安装)
4. [快速开始（约 10 分钟）](#4-快速开始约-10-分钟)
5. [核心概念](#5-核心概念)
6. [启动配置](#6-启动配置)
7. [磁盘缓存 MediaCache](#7-磁盘缓存-mediacache)
8. [资源择优 MediaSelector](#8-资源择优-mediaselector)
9. [播放控制 MediaPlayerController](#9-播放控制-mediaplayercontroller)
10. [全局协调 MediaSession](#10-全局协调-mediasession)
11. [UI 组件](#11-ui-组件)
12. [把自家模型映射成 MediaRef](#12-把自家模型映射成-mediaref)
13. [运行 Example](#13-运行-example)
14. [原生与依赖说明](#14-原生与依赖说明)
15. [公开 API 一览](#15-公开-api-一览)
16. [常见问题](#16-常见问题)

---

## 1. 它解决什么问题

在多个 Flutter 项目里，媒体能力往往重复实现：按类型分盘缓存、下载去重、音视频互斥、离开画面暂停等。

`media_core` 把这些抽成基础设施：

| 你提供 | 本包负责 |
|--------|----------|
| 资源 URL / 本地绝对路径（任意 HTTP、RPC、仓库拿到即可） | 磁盘缓存、并发下载限流、URL hash 去重 |
| `MediaRef`（中立描述） | 图 / 音 / 视 / LivePhoto 播放 |
| （可选）登出回调、占位 Widget | 全局互斥、可见性暂停钩子 |

**一句话契约：** 给定 URL 或 `MediaRef` → 缓存 + 播放（含互斥 / 可见性策略）。

---

## 2. 能力边界

### 一期包含

- `image` / `audio` / `video` 播放
- LivePhoto **播放**（封面 + 短视频；可静音 / 循环）
- `MediaCache`：按 `MediaKind` 分仓、下载去重、并发限制、视频预览图
- `MediaSelector`：多清晰度 / 多码率候选择优
- `MediaSession`：音视频互斥、可见性暂停/恢复钩子、登出清理
- 最小 UI：`MediaView` / `MediaPlayerView`（基于 `ValueListenableBuilder`，无 GetX）

### 明确不包含

| 项 | 说明 |
|----|------|
| 业务 API / 数据仓库 | URL 由宿主任意方式获取 |
| 上传 | 另一域能力 |
| LivePhoto **列表自动播队列** | 产品策略，未进内核 |
| DynamicAvatar 帧管线 | 用 `video` + 静音循环即可覆盖常见需求 |
| GetX | 状态一律 `ValueNotifier` / Flutter 原语 |

---

## 3. 安装

在宿主 `pubspec.yaml` 中：

```yaml
dependencies:
  media_core:
    path: ../media_core          # monorepo path
    # 或：
    # git:
    #   url: <your-git-url>
    #   path: packages/media_core
```

然后：

```bash
flutter pub get
```

导入：

```dart
import 'package:media_core/media_core.dart';
```

---

## 4. 快速开始（约 10 分钟）

### 4.1 初始化

```dart
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureMediaCore(const MediaCoreConfig());
  runApp(const MyApp());
}
```

### 4.2 只做缓存

```dart
final file = await MediaCache.instance.getFile(
  'https://example.com/a.mp4',
  MediaKind.video,
  onProgress: (p) => debugPrint('progress=$p'),
);
debugPrint('local path: ${file.path}');
```

### 4.3 播放（Controller）

```dart
final controller = MediaPlayerController();
controller.bind(MediaRef.video(
  'https://example.com/a.mp4',
  coverUrl: 'https://example.com/cover.jpg',
));

final result = await controller.play();
if (result.isErr) {
  debugPrint('play failed: ${result.errorOrNull}');
}

// 监听状态（无 GetX）
controller.playbackState.addListener(() {
  debugPrint('state=${controller.playbackState.value}');
});

// 用完务必 dispose
await controller.dispose();
```

### 4.4 播放（开箱 Widget）

```dart
MediaPlayerView(
  media: MediaRef.video(
    'https://example.com/a.mp4',
    coverUrl: 'https://example.com/cover.jpg',
  ),
  autoPlay: false,
  showControls: true,
)
```

展示静态图：

```dart
MediaView(
  ref: MediaRef.image('https://example.com/photo.jpg'),
  fit: BoxFit.cover,
  height: 200,
)
```

---

## 5. 核心概念

### 5.1 `MediaKind`

缓存与播放策略的隔离维度：

| 值 | 用途 |
|----|------|
| `image` | 普通图片 |
| `video` | 普通视频（走磁盘缓存后本地播） |
| `audio` | 音频 |
| `stream` | 流式视频（网络 URL 直连，不先整文件落盘） |
| `coverImage` | 封面图缓存仓 |
| `previewImage` | 视频预览图缓存仓 |
| `livePhoto` | LivePhoto（薄视频配置：可静音/循环） |
| `unknown` | 兜底 |

### 5.2 `MediaRef` / `MediaVariant`

`MediaRef` 是与后端无关的资源描述，也是本包的主输入。

```dart
MediaRef(
  id: 'optional-host-id',           // 可选，便于日志 / 互斥辨识
  url: 'https://cdn.example/v.mp4', // 主 URL，或以 `/` 开头的本地绝对路径
  kind: MediaKind.video,
  coverUrl: 'https://cdn.example/c.jpg',
  meta: MediaMeta(width: 1280, height: 720, title: 'Demo'),
  variants: [                       // 可选：多清晰度 / 多码率候选
    MediaVariant(
      url: 'https://cdn.example/v_720.mp4',
      kind: MediaKind.video,
      meta: MediaMeta(width: 1280, height: 720),
    ),
    MediaVariant(
      url: 'https://cdn.example/v_480.mp4',
      kind: MediaKind.video,
      meta: MediaMeta(width: 854, height: 480),
    ),
  ],
);
```

便捷工厂：

```dart
MediaRef.image(url);
MediaRef.video(url, coverUrl: cover);
MediaRef.audio(url, coverUrl: cover);
MediaRef.livePhoto(videoUrl, coverUrl: cover);
```

**本地文件：** `url` 以 `/` 开头时视为本地绝对路径，跳过下载，直接打开文件。

### 5.3 `MediaPlaybackState`

`stopped` / `playing` / `paused` / `buffering` / `error`

### 5.4 `MediaResult`

轻量结果类型，避免依赖宿主工程的 Result 工具：

```dart
final result = await controller.play();
if (result is MediaOk) { /* ok */ }
if (result is MediaErr) { debugPrint('${result.error}'); }

// 或
if (result.isOk) { ... }
if (result.isErr) { debugPrint('${result.errorOrNull}'); }
```

---

## 6. 启动配置

`configureMediaCore` 建议在 `main` 里调用一次（基础用法也可省略，使用默认配置）。

```dart
await configureMediaCore(
  MediaCoreConfig(
    // 注入宿主日志（可选）
    logger: MyAppMediaLogger(),

    // 自定义占位 / 错误 UI（可选）
    placeholderBuilder: (context) => const ColoredBox(color: Colors.black12),
    errorBuilder: (context) => const Icon(Icons.broken_image),

    // 播放策略
    policy: const MediaPlaybackPolicy(
      pauseWhenNotVisible: true, // 离开视口时暂停（由 Visibility 钩子触发）
    ),

    // 登出时清理播放器与进行中的下载（账号体系由宿主决定）
    registerLogoutCleanup: (cleanup) {
      // 例如：Auth.onLogout(cleanup);
      // 或：CheckpointService().addListener(onLoggedOut: cleanup);
    },
  ),
);
```

实现自定义日志：

```dart
class MyAppMediaLogger implements MediaCoreLogger {
  @override
  void d(String message) => /* your log */ null;

  @override
  void w(String message) => /* ... */ null;

  @override
  void e(String message, [Object? error, StackTrace? stackTrace]) => /* ... */ null;
}
```

---

## 7. 磁盘缓存 MediaCache

单例：`MediaCache.instance`（也可用 `MediaCache()`）。

### 7.1 下载或命中缓存

```dart
// 按 URL + kind
final file = await MediaCache.instance.getFile(url, MediaKind.audio);

// 按 MediaRef（取 effectiveVariants 的第一个）
final file2 = await MediaCache.instance.getRef(ref);
```

行为要点：

- 按 `MediaKind` 使用**独立** `CacheManager`，策略互不干扰
- 缓存 key = URL 的 SHA256
- 同一 URL 并发请求会合并为一个下载
- 默认最大并发下载数：`maxConcurrentDownloads = 5`（可改）

### 7.2 仅查询缓存（不触发下载）

```dart
final cached = await MediaCache.instance.getCachedFile(url, MediaKind.image);
if (cached == null) {
  // 未命中
}
```

### 7.3 视频预览图

```dart
final preview = await MediaCache.instance.getVideoPreviewFile(
  videoUrl,
  maxWidth: 512,
  quality: 75,
);
```

### 7.4 清理与统计

```dart
await MediaCache.instance.cleanCache(olderThan: const Duration(days: 7));
await MediaCache.instance.clearAllCache();
final bytes = await MediaCache.instance.getCacheSize();
MediaCache.instance.cancelAllDownloads(); // 登出时 Session 也会调用
```

### 7.5 与图片 Widget 共用缓存

```dart
// ImageProvider
Image(image: MediaImageProvider(url));

// 或便捷组件
MediaImageProvider.network(
  url,
  resourceKind: MediaKind.image,
  fit: BoxFit.cover,
);
```

---

## 8. 资源择优 MediaSelector

当 `MediaRef.variants` 有多条候选时，可用选择器按目标尺寸 / 码率排序：

```dart
final bestImage = MediaSelector.bestImage(
  ref,
  preferredWidth: 400,
  preferredHeight: 400,
  allowAnimated: false,
);

final videos = MediaSelector.playableVideos(
  ref,
  preferredWidth: 1280,
  preferredHeight: 720,
);

final audios = MediaSelector.playableAudio(
  ref,
  preferredBitrate: 128000,
);

final streams = MediaSelector.playableStreams(
  ref,
  preferredBandwidth: 2_000_000,
);
```

`MediaPlayerController` 绑定时会按类型自动调用上述择优逻辑，一般无需手写。

---

## 9. 播放控制 MediaPlayerController

### 9.1 生命周期

```dart
final controller = MediaPlayerController(
  livePhotoMuted: true,    // 仅 livePhoto 有意义
  livePhotoLooping: true,
);

controller.bind(mediaRef);   // 每个 controller 只绑一个 MediaRef
await controller.play();
await controller.pause();
await controller.seek(const Duration(seconds: 10));
await controller.setVolume(0.8);
await controller.stop();
await controller.dispose();  // 必须调用，会从 MediaSession 注销
```

### 9.2 状态监听（无 GetX）

```dart
ValueListenableBuilder<MediaPlaybackState>(
  valueListenable: controller.playbackState,
  builder: (context, state, _) => Text('$state'),
);

// 还有：
// controller.position
// controller.duration
// controller.volume
```

### 9.3 视频画面

视频 / LivePhoto 初始化成功后：

```dart
final videoController = controller.videoAdapter?.videoPlayerController;
if (videoController != null && videoController.value.isInitialized) {
  // 使用 package:video_player 的 VideoPlayer(videoController)
}
```

`MediaPlayerView` 已封装这一层，多数场景直接用 Widget 即可。

### 9.4 类型 → Adapter 映射

| `MediaKind` | Adapter |
|-------------|---------|
| `image` / cover / preview / unknown | `ImagePlaybackAdapter`（无真实播放） |
| `audio` | `AudioPlaybackAdapter`（flutter_sound） |
| `video` / `stream` | `VideoPlaybackAdapter`（video_player + fvp） |
| `livePhoto` | `LivePhotoPlaybackAdapter`（视频 + 静音/循环配置） |

---

## 10. 全局协调 MediaSession

单例：`MediaSession.instance`。

### 10.1 播放互斥

在 `play()` 前由 Controller 自动调用 `requestPlayback`：

| 正在播放类型 | 会停掉的其他类型 |
|--------------|------------------|
| `audio` | 其他 `audio` |
| `video` / `livePhoto` / `stream` | 其他 `video` / `livePhoto` / `stream` |
| `image` 等 | 不互斥 |

因此同一时刻通常只有一路音频，或一路「视频类」在播。

### 10.2 可见性暂停 / 恢复

宿主或 `MediaPlayerView` 在可见性变化时调用：

```dart
await MediaSession.instance.onVisibilityChanged(
  controller,
  visible: info.visibleFraction >= 1.0,
);
```

当 `MediaPlaybackPolicy.pauseWhenNotVisible == true` 时：

- 不可见 → 自动 `pause`，并标记 `isVisibilityPaused`
- 再次可见 → 自动 `play` 恢复

### 10.3 登出清理

通过 `MediaCoreConfig.registerLogoutCleanup` 注册后，登出时会：

1. `forceStop` 所有已注册 Controller  
2. `MediaCache.cancelAllDownloads()`

也可手动：

```dart
MediaSession.instance.handleLogout();
```

---

## 11. UI 组件

### 11.1 `MediaView`

静态展示（图 / 封面）：

```dart
MediaView(
  ref: MediaRef.image(url),
  fit: BoxFit.cover,
  width: double.infinity,
  height: 200,
  preferredWidth: 800,   // 参与多候选择优
  preferredHeight: 600,
)
```

占位与错误 UI 优先使用 `MediaCoreConfig` 中的 builder。

### 11.2 `MediaPlayerView`

最小播放壳（控件 + 画面 + 可见性作用域）：

```dart
MediaPlayerView(
  media: MediaRef.video(url, coverUrl: cover),
  // controller: 外部传入则由外部负责 dispose
  autoPlay: false,
  showControls: true,
  aspectRatio: 16 / 9,
)
```

### 11.3 `MediaVisibilityScope`

若自建 UI，可用该组件把可见性回调接到 Session：

```dart
MediaVisibilityScope(
  controllerKey: ValueKey(ref.url),
  onVisibilityChanged: (visible) {
    MediaSession.instance.onVisibilityChanged(controller, visible: visible);
  },
  child: yourPlayerUi,
)
```

---

## 12. 把自家模型映射成 MediaRef

本包**不认识**你的后端模型。在宿主写一层 Mapper 即可，例如：

```dart
/// 示例：任意 DTO → MediaRef（伪代码）
MediaRef mapMyDto(MyMediaDto dto) {
  switch (dto.type) {
    case MyType.image:
      return MediaRef.image(
        dto.url,
        id: dto.id,
        meta: MediaMeta(width: dto.width, height: dto.height),
        variants: dto.candidates
            .map((c) => MediaVariant(
                  url: c.url,
                  kind: MediaKind.image,
                  meta: MediaMeta(width: c.width, height: c.height),
                ))
            .toList(),
      );
    case MyType.video:
      return MediaRef.video(
        dto.url,
        id: dto.id,
        coverUrl: dto.coverUrl,
        meta: MediaMeta(duration: Duration(milliseconds: dto.durationMs)),
      );
    case MyType.audio:
      return MediaRef.audio(dto.url, id: dto.id, coverUrl: dto.coverUrl);
    case MyType.live:
      return MediaRef.livePhoto(
        dto.videoUrl,
        id: dto.id,
        coverUrl: dto.coverUrl!,
      );
  }
}
```

网络请求可用 Dio、http、自研 RPC、GraphQL——**本包只消费最终 URL**。

---

## 13. 运行 Example

独立演示 App（纯公开 URL，零业务 API）：

```bash
cd packages/media_core/example
flutter pub get
flutter run
```

Example 含四个 Tab：Image / Video / Audio / Mutex（双视频互斥）。

---

## 14. 原生与依赖说明

| 能力 | 依赖 |
|------|------|
| 视频 | `video_player` + `fvp`（适配器内自动 `registerWith`） |
| 音频 | `flutter_sound` + `audio_session` |
| 图片缓存 | `cached_network_image` + `flutter_cache_manager` |
| 可见性 | `visibility_detector` |
| 视频缩略图 | `video_thumbnail` |

宿主需自行处理：

- 网络权限（Android `INTERNET` 等）
- 若需后台音频 / 锁屏控制：按 `audio_session` / 系统要求配置（本期 Session **未**内置完整 `audio_service` 系统媒体会话，可按项目需要后续扩展）
- iOS 模拟器 / 真机对编解码器的差异（fvp 用于拓宽编码支持）

---

## 15. 公开 API 一览

从 `package:media_core/media_core.dart` 导出：

| 类别 | 符号 |
|------|------|
| 启动 | `configureMediaCore` / `MediaCoreConfig` / `MediaPlaybackPolicy` / `MediaCoreLogger` |
| 模型 | `MediaKind` / `MediaRef` / `MediaVariant` / `MediaMeta` / `MediaPlaybackState` / `MediaResult` |
| 缓存 | `MediaCache` / `MediaImageProvider` |
| 择优 | `MediaSelector` |
| 播放 | `MediaPlayerController` / `MediaSession` |
| UI | `MediaView` / `MediaPlayerView` / `MediaVisibilityScope` |

各 `*PlaybackAdapter` **不**从主 barrel 导出，属于内部实现。

---

## 16. 常见问题

**Q: 必须先调 `configureMediaCore` 吗？**  
A: 基础缓存/播放可以不调（使用默认配置）。需要自定义日志、占位、登出清理、可见性策略时再配置。

**Q: 和业务 API 包什么关系？**  
A: 无关系。先用你自己的仓库拿到 URL，再交给 `media_core`。

**Q: 为什么不用 GetX？**  
A: 独立包要对任意新项目友好；状态用 `ValueNotifier` 即可。

**Q: LivePhoto 列表里自动轮流播？**  
A: 一期不做。仅支持 LivePhoto 作为「可静音循环的短视频」播放。

**Q: 动态头像怎么办？**  
A: 使用 `MediaRef.video(...)` + `LivePhotoPlaybackAdapter` 同类配置（静音循环），或自行包一层 UI；不引入独立帧管线。

**Q: 主工程会不会被改动？**  
A: 本包从母本只读抽取，**不要求也不修改**主工程；主工程回接属于另案。

---

## 版本

见 [CHANGELOG.md](./CHANGELOG.md)。当前为 `0.1.0` 初版抽取。
