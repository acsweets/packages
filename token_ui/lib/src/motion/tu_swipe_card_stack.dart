// 通用滑动卡片组件
//
// 对应 PRD「4.3 操作按钮」「4.4 交互行为」「4.4.4 撤销」的通用交互逻辑：
// - 左滑 / 右滑超过阈值触发对应回调，未超过阈值卡片回弹
// - 拖拽过程中实时上报进度（-1 ~ 1），供外部按钮联动放大/反色
// - 支持点击卡片（非按钮区域）触发单独回调
// - 支持外部 Controller 以编程方式触发滑动（对应「点击按钮触发操作」）
// - 剩余卡片数 <= replenishThreshold 时触发 onNeedMore（对应 4.5 卡片补给）
// - 不支持撤销（对应 4.4.4），是设计上的隐式约束：本组件没有暴露任何 undo API
//
// 手势说明：顶层卡片使用 [GestureDetector.onHorizontalDrag*] 而非 onPan*，
// 避免与外层 [CustomScrollView] 的竖向滚动抢手势。
//
// 本文件只关心「滑动的通用机制」，不关心卡片长什么样——
// 卡片内容通过 cardBuilder 传入，可以是 creator 卡片、商品卡片、任何东西。

import 'package:flutter/material.dart';

enum TuSwipeDirection { left, right }

/// 用于从外部（比如底部按钮）触发滑动的控制器。
///
/// 使用示例：
/// ```dart
/// TuSwipeCardStack<Creator>(
///   backCardOffsetStep: 24,   // 想要背后卡片露出更多，调大这个值
///   backCardScaleStep: 0.08,  // 想要缩放差异更明显，调大这个值
///   ...
/// )
/// ```
class TuSwipeCardController {
  _TuSwipeCardStackState? _state;

  void _attach(_TuSwipeCardStackState state) => _state = state;

  /// 触发一次「跳过」，等价于用户左滑超过阈值。
  void swipeLeft() => _state?._triggerProgrammaticSwipe(TuSwipeDirection.left);

  /// 触发一次「成为 member」，等价于用户右滑超过阈值。
  void swipeRight() => _state?._triggerProgrammaticSwipe(TuSwipeDirection.right);
}

class TuSwipeCardStack<T> extends StatefulWidget {
  /// 当前卡片栈数据，第一个元素为最上面的卡片。
  final List<T> items;

  /// 卡片内容构建器。[depth] 为 0 表示最上面可交互的卡片，1、2... 为背后的卡片。
  final Widget Function(BuildContext context, T item, int depth) cardBuilder;

  /// 左滑（或点击左按钮）超过阈值后触发，item 为被划走的卡片对应数据。
  final void Function(T item)? onSwipeLeft;

  /// 右滑（或点击右按钮）超过阈值后触发。
  final void Function(T item)? onSwipeRight;

  /// 点击卡片非按钮区域时触发。
  final void Function(T item)? onTapCard;

  /// 拖拽/滑动过程中实时回调，progress 范围 -1（左满）~ 1（右满），0 为居中。
  /// 用于驱动外部按钮的放大/反色联动。
  final void Function(double progress)? onDragUpdate;

  /// 剩余卡片数 <= replenishThreshold 时触发一次，用于提前请求下一批数据。
  /// 同一批数据只会触发一次，直到 items 发生变化才会重新允许触发。
  final VoidCallback? onNeedMore;
  final int replenishThreshold;

  /// 同时渲染几张卡片（包含最上面这张），用于做叠放视觉效果。
  final int visibleCount;

  /// 触发滑出的水平位移阈值（px）。
  final double swipeThreshold;

  /// 背后每一层卡片相对上一层的纵向偏移量（px），用于叠放视觉效果。
  /// 例如 depth=1 的卡片会下移 backCardOffsetStep，depth=2 下移 backCardOffsetStep*2，以此类推。
  final double backCardOffsetStep;

  /// 背后每一层卡片相对上一层的缩放递减比例（0~1）。
  /// 例如 0.05 表示 depth=1 缩小到 95%，depth=2 缩小到 90%。
  final double backCardScaleStep;

  final TuSwipeCardController? controller;

  /// 首次加载中，且 items 为空时展示。
  final bool isLoading;
  final WidgetBuilder? loadingBuilder;

  /// items 为空且不在 loading 状态时展示（对应 4.5 空状态 / 7 异常边界）。
  final WidgetBuilder? emptyBuilder;

  const TuSwipeCardStack({
    super.key,
    required this.items,
    required this.cardBuilder,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onTapCard,
    this.onDragUpdate,
    this.onNeedMore,
    this.replenishThreshold = 3,
    this.visibleCount = 2,
    this.swipeThreshold = 120,
    this.backCardOffsetStep = 16,
    this.backCardScaleStep = 0.05,
    this.controller,
    this.isLoading = false,
    this.loadingBuilder,
    this.emptyBuilder,
  });

  @override
  State<TuSwipeCardStack<T>> createState() => _TuSwipeCardStackState<T>();
}

class _TuSwipeCardStackState<T> extends State<TuSwipeCardStack<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  Animation<Offset>? _animation;
  Animation<double>? _promoteAnimation;
  VoidCallback? _animationListener;

  Offset _dragOffset = Offset.zero;

  /// 当前正在拖拽 / 飞出的卡片；位移只作用于该卡片，避免切换顶层时串位。
  T? _dragItem;

  /// 顶层卡片从背后升上来时的进度（0 = 背后卡片视觉，1 = 全尺寸）。
  double _promoteProgress = 1.0;

  bool _dragging = false;
  bool _requestedMore = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didUpdateWidget(covariant TuSwipeCardStack<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller?._attach(this);
    // 新数据到位后，重新允许下一次补给请求。
    if (widget.items.length != oldWidget.items.length) {
      _requestedMore = false;
    }

    if (widget.items.isEmpty) {
      _dragOffset = Offset.zero;
      _dragItem = null;
      _promoteProgress = 1.0;
      return;
    }

    final topChanged = oldWidget.items.isNotEmpty &&
        widget.items.first != oldWidget.items.first;
    if (!topChanged) return;

    _dragOffset = Offset.zero;
    _dragItem = null;

    final removedTopCard = widget.items.length < oldWidget.items.length;
    if (removedTopCard) {
      _startPromoteAnimation();
    } else {
      _promoteProgress = 1.0;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _maybeRequestMore() {
    if (_requestedMore) return;
    if (widget.items.length <= widget.replenishThreshold) {
      _requestedMore = true;
      // 在 build 结束后触发，避免在 build 过程中调用 setState。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onNeedMore?.call();
      });
    }
  }

  bool _isDragItem(T item) => _dragItem != null && _dragItem == item;

  // ---------------- 手势（仅水平，不与外层竖向 ScrollView 竞争） ----------------

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_animController.isAnimating) {
      if (_promoteProgress >= 1.0) return;
      _removeAnimationListener();
      _animController.stop();
    }
    if (widget.items.isEmpty) return;
    setState(() {
      _dragging = true;
      _dragItem = widget.items.first;
      _dragOffset = Offset.zero;
      _promoteProgress = 1.0;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final deltaX = details.primaryDelta;
    if (deltaX == null) return;
    setState(() => _dragOffset += Offset(deltaX, 0));
    final progress = (_dragOffset.dx / widget.swipeThreshold).clamp(-1.0, 1.0);
    widget.onDragUpdate?.call(progress);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (_dragOffset.dx.abs() >= widget.swipeThreshold) {
      final dir = _dragOffset.dx > 0
          ? TuSwipeDirection.right
          : TuSwipeDirection.left;
      _flyOut(dir);
    } else {
      _bounceBack();
    }
  }

  // ---------------- 动画 ----------------

  void _removeAnimationListener() {
    if (_animationListener != null) {
      _animController.removeListener(_animationListener!);
      _animationListener = null;
    }
  }

  void _bounceBack() {
    _removeAnimationListener();
    final tween = Tween<Offset>(begin: _dragOffset, end: Offset.zero);
    _animation = tween.animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animationListener = () {
      setState(() => _dragOffset = _animation!.value);
      final progress = (_dragOffset.dx / widget.swipeThreshold).clamp(
        -1.0,
        1.0,
      );
      widget.onDragUpdate?.call(progress);
    };
    _animController.addListener(_animationListener!);
    _animController
      ..reset()
      ..forward().whenComplete(_removeAnimationListener);
  }

  void _flyOut(TuSwipeDirection dir) {
    if (widget.items.isEmpty) return;
    _dragItem ??= widget.items.first;

    final width = MediaQuery.of(context).size.width;
    final endX = dir == TuSwipeDirection.right ? width * 1.6 : -width * 1.6;

    _removeAnimationListener();
    final tween = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy),
    );
    _animation = tween.animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animationListener = () {
      setState(() => _dragOffset = _animation!.value);
    };
    _animController.addListener(_animationListener!);
    _animController
      ..reset()
      ..forward().whenComplete(() {
        _removeAnimationListener();
        _completeSwipe(dir);
      });
  }

  void _completeSwipe(TuSwipeDirection dir) {
    if (widget.items.isEmpty) return;
    final item = widget.items.first;

    widget.onDragUpdate?.call(0);
    if (dir == TuSwipeDirection.right) {
      widget.onSwipeRight?.call(item);
    } else {
      widget.onSwipeLeft?.call(item);
    }
    // _dragOffset 重置与升层动画由 didUpdateWidget 在 items 更新后处理。
  }

  /// 新顶层卡片从背后尺寸平滑过渡到全尺寸，避免瞬间弹出。
  void _startPromoteAnimation() {
    _removeAnimationListener();
    _promoteProgress = 0;
    _promoteAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animationListener = () {
      setState(() => _promoteProgress = _promoteAnimation!.value);
    };
    _animController.addListener(_animationListener!);
    _animController
      ..reset()
      ..forward().whenComplete(() {
        _removeAnimationListener();
        if (mounted) {
          setState(() => _promoteProgress = 1.0);
        }
      });
  }

  void _triggerProgrammaticSwipe(TuSwipeDirection dir) {
    if (widget.items.isEmpty || _animController.isAnimating) return;
    _dragItem = widget.items.first;
    // 立刻把进度打满，让按钮先做出「放大反色」反馈，再飞出卡片。
    widget.onDragUpdate?.call(dir == TuSwipeDirection.right ? 1.0 : -1.0);
    _flyOut(dir);
  }

  // ---------------- 构建 ----------------

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    if (widget.items.isEmpty) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    _maybeRequestMore();

    final visible = widget.items.take(widget.visibleCount).toList();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int i = visible.length - 1; i >= 0; i--)
          _buildCard(context, visible[i], i),
      ],
    );
  }

  Widget _buildCard(BuildContext context, T item, int depth) {
    final cardKey = ObjectKey(item);
    final isTop = depth == 0;
    final isDragTarget = isTop && _isDragItem(item);
    final dragOffset = isDragTarget ? _dragOffset : Offset.zero;
    final angle =
        isDragTarget ? (_dragOffset.dx / 300).clamp(-0.4, 0.4) : 0.0;

    final double scale;
    final double dy;
    if (isTop) {
      final promote = _promoteProgress.clamp(0.0, 1.0);
      scale = 1.0 - (1.0 - promote) * widget.backCardScaleStep;
      dy = (1.0 - promote) * widget.backCardOffsetStep;
    } else {
      scale = 1 - depth * widget.backCardScaleStep;
      dy = depth * widget.backCardOffsetStep;
    }

    // 所有层级使用相同的 wrapper 结构，确保卡片升层时子 Element（含图片）不被销毁。
    // 顶层仅监听水平拖拽，竖向手势交给外层 ScrollView。
    return Positioned.fill(
      key: cardKey,
      child: IgnorePointer(
        ignoring: !isTop,
        child: GestureDetector(
          onHorizontalDragStart: isTop ? _onHorizontalDragStart : null,
          onHorizontalDragUpdate: isTop ? _onHorizontalDragUpdate : null,
          onHorizontalDragEnd: isTop ? _onHorizontalDragEnd : null,
          onTap: isTop ? () => widget.onTapCard?.call(item) : null,
          behavior: HitTestBehavior.deferToChild,
          child: Transform.translate(
            offset: Offset(dragOffset.dx, dragOffset.dy + dy),
            child: Transform.scale(
              scale: scale,
              child: Transform.rotate(
                angle: angle,
                child: widget.cardBuilder(context, item, depth),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
