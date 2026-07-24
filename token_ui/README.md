# token_ui

基于 **Design Token** 的 Flutter UI 组件库。

宿主项目可以整包替换颜色 / 字体；若不提供主题，组件自动使用内置的亮色 / 暗色默认 Token。  
本包托管于 [acsweets/packages](https://github.com/acsweets/packages)，与 `screen_protect` 等同仓维护。

---

## 目录

- [设计理念](#设计理念)
- [安装](#安装)
- [快速开始](#快速开始)
- [主题系统（Token）](#主题系统token)
- [自适应尺寸](#自适应尺寸)
- [组件一览](#组件一览)
- [常用用法示例](#常用用法示例)
- [Example Gallery](#example-gallery)
- [不在本包范围内的内容](#不在本包范围内的内容)
- [目录结构](#目录结构)
- [开发与质量检查](#开发与质量检查)
- [版本](#版本)

---

## 设计理念

```
宿主传入自定义 Token（可选）
        ↓ 未传 / 未包 TuTheme
包内 Built-in 默认 Token（亮 / 暗）
        ↓
Tu* 组件只读 Token 渲染
```

核心原则：

1. **换肤不改组件**：换一套 `TuColors` / `TuTextStyles`，全库外观跟着变。  
2. **零配置可用**：不包 `TuTheme` 也能渲染（回退到内置暗色默认）。  
3. **纯 UI**：不依赖业务 Service、RPC、路由框架；导航只使用 Flutter `Navigator`。  
4. **前缀统一**：对外类型一律 `Tu*`（如 `TuButton`、`TuTheme`）。

Token 解析顺序：

```
组件 build
  → TuTheme.maybeOf(context)
       ├─ 有 → 使用宿主 colors / textStyles / mode
       └─ 无 → TuColors.builtIn + TuTextStyles.builtIn
  → 组件自身 props 局部覆盖（优先级最高）
  → 绘制
```

在 Widget 内取 Token：

```dart
context.colors.text.primary
context.styles.title[4]
context.colors.button.neutral / 50   // 透明度 0–100
context.styles.body[2] + context.colors.text.link
```

---

## 安装

### Git 依赖（推荐，与 screen_protect 相同）

```yaml
dependencies:
  token_ui:
    git:
      url: git@github.com:acsweets/packages.git
      path: token_ui
      # ref: <commit-hash 或 tag>   # 建议锁定版本
```

HTTPS：

```yaml
dependencies:
  token_ui:
    git:
      url: https://github.com/acsweets/packages.git
      path: token_ui
```

### 本地 path（联调）

```yaml
dependencies:
  token_ui:
    path: ../packages/token_ui
```

然后：

```bash
flutter pub get
```

---

## 快速开始

### 零配置

```dart
import 'package:flutter/material.dart';
import 'package:token_ui/token_ui.dart';

void main() {
  runApp(
    TuTheme(
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: TuButton.neutral.large(
              label: 'Hello',
              onPressed: () {},
            ),
          ),
        ),
      ),
    ),
  );
}
```

`TuTheme` **可以省略**。省略时组件内部通过 `TuTheme.resolve` 使用内置默认 Token。

### 推荐：配合 ScreenUtil

设计稿基准尺寸建议 **750 × 1624**（与蓝本一致）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:token_ui/token_ui.dart';

void main() {
  runApp(
    ScreenUtilInit(
      designSize: const Size(750, 1624),
      minTextAdapt: true,
      builder: (context, child) {
        return TuTheme(
          mode: ThemeMode.dark,
          child: MaterialApp(
            home: child,
          ),
        );
      },
      child: const HomePage(),
    ),
  );
}
```

---

## 主题系统（Token）

### TuTheme

| 参数 | 类型 | 说明 |
|------|------|------|
| `mode` | `ThemeMode` | 默认 `ThemeMode.dark`；`system` 时按暗色处理 |
| `colors` | `TuColors?` | 自定义色板；`null` 则用 `TuColors.builtIn(mode)` |
| `textStyles` | `TuTextStyles?` | 自定义字体阶；`null` 则用内置 |
| `child` | `Widget` | 子树 |

只导出主题时也可：

```dart
import 'package:token_ui/theme.dart';
```

### TuColors 语义结构

| 分组 | 字段示例 | 用途 |
|------|----------|------|
| `bg` | `page` / `primary` / `secondary` / `component` / `inputfield` | 页面与容器背景 |
| `component` | `stroke` / `border` | 描边、分割线 |
| `mask` | `light` / `primary` / `heavy` | 遮罩 |
| `text` | `primary` / `secondary1`… / `placeholder` / `invert` / `link` / `highlight` | 文字 |
| `button` | `primary` / `secondary` / `neutral` | 按钮填充 |
| `error` | `primary` / `secondary` | 错误 / 危险 |
| `success` | `Color` | 成功态 |

内置色板：

```dart
TuColors.builtIn(ThemeMode.dark);
TuColors.builtIn(ThemeMode.light);
```

### 自定义品牌色

实现同一套结构后整包传入即可：

```dart
final brandDark = TuColors(
  mode: ThemeMode.dark,
  bg: const TuBgColors(
    page: Color(0xFF1A120B),
    primary: Color(0xFF241810),
    secondary: Color(0xFF2E2016),
    component: Color(0xFF3D2B1C),
    inputfield: Color(0xFF241810),
  ),
  component: const TuComponentColors(
    stroke: Color(0xFF8B5E3C),
    border: Color(0xFFD4A574),
  ),
  mask: TuMaskColors(
    light: const Color(0xFF1A120B).withValues(alpha: 0.3),
    primary: const Color(0xFF1A120B).withValues(alpha: 0.6),
    heavy: const Color(0xFF1A120B).withValues(alpha: 0.8),
  ),
  text: const TuTextColors(
    primary: Color(0xFFFFF1E0),
    secondary1: Color(0xFFD4A574),
    secondary2: Color(0xFFE8C9A8),
    secondary3: Color(0xFFFFD6A8),
    placeholder: Color(0xFF8B5E3C),
    invert: Color(0xFF241810),
    link: Color(0xFFFF8A50),
    highlight: Color(0xFFFFC107),
  ),
  button: const TuButtonColors(
    primary: Color(0xFFFFF1E0),
    secondary: Color(0xFF3D2B1C),
    neutral: Color(0xFFC45C26),
  ),
  error: const TuErrorColors(
    primary: Color(0xFFEF5350),
    secondary: Color(0xFFE57373),
  ),
  success: const Color(0xFF66BB6A),
);

TuTheme(
  mode: ThemeMode.dark,
  colors: brandDark,
  textStyles: TuTextStyles.builtIn(fontFamily: 'MyFont'),
  child: app,
);
```

完整 Brand 演示见 `example/lib/brand_theme_demo.dart`。

### TuTextStyles

字号阶用 **1-based 下标**（如 `styles.title[4]`）：

| 系列 | 场景 | 字重 |
|------|------|------|
| `display` | 大展示、等级卡 | w700 |
| `special` | 特殊强调（如名字） | w900 |
| `headline` | 标题强调 | w600 |
| `title` | 标题 | w500 |
| `body` | 正文 | w400 |
| `meta` | 辅助信息、时间 | w300 |
| `link` | 链接 | w400 |

颜色与样式组合运算符：

```dart
Text(
  '链接文字',
  style: context.styles.link[2] + context.colors.text.link / 80,
);
```

---

## 自适应尺寸

扩展名与蓝本一致：`.aw` / `.ah` / `.asp` / `.ar` / `.asw` / `.ash`。

| 扩展 | 含义 |
|------|------|
| `.aw` | 按设计稿宽度缩放（布局宽高常用） |
| `.asp` | 字号缩放 |
| `.ar` | 圆角等通用缩放 |
| `.asw` / `.ash` | 屏宽 / 屏高百分比 |

行为：

- 已初始化 `ScreenUtil` → 走 `flutter_screenutil`  
- 未初始化 → **回退为原始数字**（`120.aw == 120.0`），保证组件仍能跑

---

## 组件一览

### 主题

| 类型 | 说明 |
|------|------|
| `TuTheme` / `TuThemeData` | 主题注入与解析 |
| `TuColors` 及子结构 | 颜色 Token |
| `TuTextStyles` / `TuFont` | 字体 Token |

### 基础控件（primitives）

| 组件 | 说明 |
|------|------|
| `TuButton` | 链式按钮（色调 × 边框 × 尺寸 × 宽度） |
| `TuTag` | 标签（small / medium） |
| `TuTextField` | 输入框（primary / search） |
| `TuIconButton` | 正方形图标按钮 |
| `TuBadgeWrapper` | 子组件角标包装 |
| `TuNotificationDot` | 红点 / 数字角标 |
| `TuDivider` | 分割线 |

### 反馈（feedback）

| 组件 | 说明 |
|------|------|
| `TuBottomSheet` | 通用底部弹层（业务内容自拼） |
| `TuActionSheet` | 底部操作列表 + Cancel |
| `TuActionMenu` | 锚点弹出菜单 |
| `TuEmpty` | 空状态 |
| `TuError` | 错误态 + 可选重试 |
| `TuConfirmDialog` | 确认对话框 |
| `TuBlockingLoadingOverlay` | 全局阻塞 Loading |

### 布局（layout）

| 组件 | 说明 |
|------|------|
| `TuAppBar` | 导航栏（`PreferredSizeWidget`） |
| `TuBackButton` | 返回按钮（默认 `Navigator.maybePop`） |
| `TuListItem` | 列表行 / `.menu` 工厂 |
| `TuPaginatedList` | 分页列表 + 加载更多尾部 |
| `TuRefreshScrollView` / `TuRefreshControl` | 下拉刷新 |

### 动效 / 手势（motion）

| 组件 | 说明 |
|------|------|
| `TuSwipeCardStack` | 左右滑卡片栈 |
| `TuSwipeCardController` | 外部触发滑出 |
| `TuSwipeActionButton` | 与滑动进度联动的操作按钮 |
| `TuCarouselIndicator` | 轮播指示器 |

### 装饰（decoration）

| 组件 | 说明 |
|------|------|
| `TuDashedBorder` | 虚线边框 |

---

## 常用用法示例

### 按钮

```dart
// 色调: primary / neutral / secondary / error
// 边框: solid（默认） / outline / ghost
// 尺寸: xlarge / large / medium / small / xsmall
// 宽度: fit（默认） / wide / fixedWidth

TuButton.neutral.large.wide(
  label: 'Join',
  onPressed: () {},
);

TuButton.primary.outline.medium(
  label: 'Cancel',
  onPressed: () {},
);

TuButton.error.small(
  label: 'Delete',
  isLoading: true,
  onPressed: () {},
);

// 仅图标
TuButton.neutral.medium(
  startIcon: const Icon(Icons.add),
  onPressed: () {},
);
```

### 底部弹层（业务自拼）

账单、举报等**不进本包**，用通用 Sheet 自己拼内容：

```dart
TuBottomSheet.show(
  context,
  child: Padding(
    padding: EdgeInsets.all(32.aw),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('标题', style: context.styles.title[4] + context.colors.text.primary),
        // ... 业务内容
      ],
    ),
  ),
);
```

### 操作表 / 确认框

```dart
TuActionSheet.show(
  context,
  items: [
    TuActionSheetItem(label: '分享', onTap: () {}),
    TuActionSheetItem(
      label: '删除',
      isDestructive: true,
      onTap: () {},
    ),
  ],
);

final ok = await TuConfirmDialog.show(
  context,
  title: '确认离开？',
  content: '未保存的内容将丢失。',
  confirmButton: '离开',
  cancelButton: '留下',
  isDestructive: true,
);
```

### 空态 / 错误态

```dart
TuEmpty.content(message: '暂无内容');
TuEmpty.result(message: '无搜索结果');

TuError.network(
  message: '网络连接失败',
  onRetry: () {},
);

// 完全自定义图标
TuEmpty(
  message: '自定义空态',
  icon: Image.asset('assets/empty.png', width: 76.aw),
);
```

### 全局 Loading

```dart
// 方式一：带 context
TuBlockingLoadingOverlay.show(context);
await doWork();
TuBlockingLoadingOverlay.dismiss();

// 方式二：绑定 NavigatorKey 后无 context 也可 show
final navKey = GlobalKey<NavigatorState>();
TuBlockingLoadingOverlay.bind(navKey);
```

### AppBar / 列表

```dart
Scaffold(
  appBar: TuAppBar(
    titleText: '设置',
    onTapBack: () => Navigator.maybePop(context),
  ),
  body: Column(
    children: [
      TuListItem.menu(title: '账号', onTap: () {}),
      const TuDivider(),
      TuListItem.menu(title: '关于', onTap: () {}),
    ],
  ),
);
```

### 滑动卡片栈

```dart
final controller = TuSwipeCardController();

TuSwipeCardStack<String>(
  controller: controller,
  items: items,
  onSwipeLeft: (item) { /* skip */ },
  onSwipeRight: (item) { /* like */ },
  onDragUpdate: (progress) { /* -1 ~ 1，驱动按钮 */ },
  cardBuilder: (context, item, depth) {
    return MyCard(data: item);
  },
);

// 外部按钮触发
controller.swipeLeft();
controller.swipeRight();
```

---

## Example Gallery

```bash
cd token_ui/example
flutter pub get
flutter run
```

Gallery 支持：

- 右上角切换 **亮 / 暗**  
- 切换 **内置 Token / Brand Token**（验证换肤）  
- 按钮、标签、输入框、Sheet、确认框、空态错误、滑动栈、指示器等演示页  

---

## 不在本包范围内的内容

| 内容 | 说明 |
|------|------|
| 账单 Sheet / 举报 Sheet | 用 `TuBottomSheet` 自行组合 |
| 媒体播放 / 上传 | 属于领域包，不进纯 UI |
| 业务 Feed 卡、头像业务壳、IM 气泡 | 留在各 App / 模块 |
| 业务 Service、RPC、自定义路由 | 禁止依赖 |

---

## 目录结构

```
token_ui/
├── pubspec.yaml
├── README.md                 ← 本文档
├── CHANGELOG.md
├── lib/
│   ├── token_ui.dart         ← 公共导出
│   ├── theme.dart            ← 仅主题导出
│   └── src/
│       ├── theme/            ← TuTheme / Colors / TextStyles / Extensions
│       ├── primitives/       ← 基础控件
│       ├── feedback/         ← 弹层与反馈
│       ├── layout/           ← AppBar / List / Refresh
│       ├── motion/           ← Swipe / Indicator
│       └── decoration/       ← DashedBorder
├── example/                  ← Gallery + Brand 演示
└── test/
```

---

## 开发与质量检查

```bash
cd token_ui
flutter pub get
dart analyze
flutter test

cd example
flutter pub get
dart analyze
flutter run
```

约束自检：

- 源码中不应出现业务 `services/`、`rpc/`、宿主 App 包名依赖  
- 主题获取不得依赖全局 Router  
- 对外仅通过 `package:token_ui/token_ui.dart`（或 `theme.dart`）引用  

---

## 版本

当前版本：**0.1.0**

变更记录见 [CHANGELOG.md](./CHANGELOG.md)。

---

## 许可证

见仓库根目录说明。
