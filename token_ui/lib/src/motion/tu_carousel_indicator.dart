import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Capsule carousel page indicator (scroll-window for 6+ pages).
class TuCarouselIndicator extends StatefulWidget {
  final int count;
  final int currentIndex;

  static const int maxVisible = 5;

  const TuCarouselIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  @override
  State<TuCarouselIndicator> createState() => _TuCarouselIndicatorState();
}

class _TuCarouselIndicatorState extends State<TuCarouselIndicator>
    with SingleTickerProviderStateMixin {
  static const double _dotWidth = 25;
  static const double _dotHeight = 8;
  static const double _minWidth = 15;
  static const double _minHeight = 4;
  static const double _spacing = 6;

  int _prevCurrentIndex = 0;
  int _prevWindowStart = 0;
  int _windowStart = 0;

  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  double get _dotStep => _dotWidth.aw + _spacing.aw;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
        );
    _prevCurrentIndex = widget.currentIndex;
    _windowStart = _calcWindowStart();
    _prevWindowStart = _windowStart;
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TuCarouselIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.currentIndex != _prevCurrentIndex) {
      _prevCurrentIndex = widget.currentIndex;
    }

    if (widget.count > TuCarouselIndicator.maxVisible) {
      _windowStart = _calcWindowStart();
      final delta = _windowStart - _prevWindowStart;

      if (delta != 0) {
        final offsetPx = delta * _dotStep;
        _slideAnimation =
            Tween<Offset>(begin: Offset(offsetPx, 0), end: Offset.zero).animate(
              CurvedAnimation(
                parent: _slideController,
                curve: Curves.easeInOut,
              ),
            );
        _slideController.forward(from: 0);
      }

      _prevWindowStart = _windowStart;
    }
  }

  int _calcWindowStart() {
    if (widget.count <= TuCarouselIndicator.maxVisible) return 0;

    final maxVisible = TuCarouselIndicator.maxVisible;
    final maxStart = widget.count - maxVisible;
    final current = widget.currentIndex;

    var start = _windowStart;

    if (current > start + maxVisible - 2) {
      start = current - (maxVisible - 2);
    } else if (current < start + 1) {
      start = current - 1;
    }

    return start.clamp(0, maxStart);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 1) return const SizedBox.shrink();

    final dots = _buildDots();

    if (widget.count > TuCarouselIndicator.maxVisible) {
      return AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: _slideAnimation.value,
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: dots,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: dots,
    );
  }

  List<Widget> _buildDots() {
    if (widget.count <= TuCarouselIndicator.maxVisible) {
      return List.generate(widget.count, (i) {
        final isActive = i == widget.currentIndex;
        return _buildDot(
          width: _dotWidth,
          height: _dotHeight,
          opacity: isActive ? 1.0 : 0.4,
          isLast: i == widget.count - 1,
        );
      });
    }

    return _buildScrollingDots();
  }

  List<Widget> _buildScrollingDots() {
    final windowStart = _windowStart;
    final maxVisible = TuCarouselIndicator.maxVisible;
    final hasOverflowLeft = windowStart > 0;
    final hasOverflowRight = windowStart + maxVisible < widget.count;
    final dots = <Widget>[];

    for (int i = 0; i < maxVisible; i++) {
      final actualIndex = windowStart + i;
      final isActive = actualIndex == widget.currentIndex;
      final isFirst = i == 0;
      final isLast = i == maxVisible - 1;
      final isSmall =
          (isFirst && hasOverflowLeft) || (isLast && hasOverflowRight);

      dots.add(
        _buildDot(
          width: isSmall ? _minWidth : _dotWidth,
          height: isSmall ? _minHeight : _dotHeight,
          opacity: isActive ? 1.0 : (isSmall ? 0.25 : 0.4),
          isLast: isLast,
        ),
      );
    }

    return dots;
  }

  Widget _buildDot({
    required double width,
    required double height,
    required double opacity,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : _spacing.aw),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: width.aw,
        height: height.aw,
        decoration: BoxDecoration(
          color: colors.text.primary.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(100.aw),
        ),
      ),
    );
  }
}
