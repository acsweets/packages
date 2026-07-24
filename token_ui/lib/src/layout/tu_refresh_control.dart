import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../theme/tu_extensions.dart';

/// Scroll view paired with [TuRefreshControl] (bouncing + no Material stretch).
class TuRefreshScrollView extends StatelessWidget {
  const TuRefreshScrollView({
    super.key,
    this.controller,
    this.primary,
    required this.slivers,
  });

  static const ScrollPhysics _scrollPhysics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  final ScrollController? controller;
  final bool? primary;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: CustomScrollView(
        controller: controller,
        primary: primary,
        physics: _scrollPhysics,
        slivers: slivers,
      ),
    );
  }
}

/// Cupertino-style pull-to-refresh control.
class TuRefreshControl extends StatelessWidget {
  const TuRefreshControl({
    super.key,
    this.refreshTriggerPullDistance = _defaultRefreshTriggerPullDistance,
    this.refreshIndicatorExtent = _defaultRefreshIndicatorExtent,
    this.indicatorSize,
    this.builder,
    this.onRefresh,
  }) : assert(refreshTriggerPullDistance > 0.0),
       assert(refreshIndicatorExtent >= 0.0),
       assert(
         refreshTriggerPullDistance >= refreshIndicatorExtent,
         'The refresh indicator cannot take more space in its final state '
         'than the amount initially created by overscrolling.',
       );

  static const double _defaultRefreshTriggerPullDistance = 100.0;
  static const double _defaultRefreshIndicatorExtent = 60.0;

  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;
  final double? indicatorSize;
  final RefreshControlIndicatorBuilder? builder;
  final RefreshCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: refreshTriggerPullDistance,
      refreshIndicatorExtent: refreshIndicatorExtent,
      builder:
          builder ??
          (
            context,
            refreshState,
            pulledExtent,
            refreshTriggerPullDistance,
            refreshIndicatorExtent,
          ) => buildRefreshIndicator(
            context,
            refreshState,
            pulledExtent,
            refreshTriggerPullDistance,
            refreshIndicatorExtent,
            indicatorSize: indicatorSize ?? 42.aw,
          ),
      onRefresh: onRefresh,
    );
  }

  static Widget buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent, {
    required double indicatorSize,
  }) {
    final double percentageComplete = clampDouble(
      pulledExtent / refreshTriggerPullDistance,
      0.0,
      1.0,
    );
    final double radius = indicatorSize / 2;
    final double topOffset = max(
      0.0,
      (refreshIndicatorExtent - indicatorSize) / 2,
    );

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            top: topOffset,
            left: 0.0,
            right: 0.0,
            child: _buildIndicatorForRefreshState(
              refreshState,
              radius,
              percentageComplete,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildIndicatorForRefreshState(
    RefreshIndicatorMode refreshState,
    double radius,
    double percentageComplete,
  ) {
    switch (refreshState) {
      case RefreshIndicatorMode.drag:
        const Curve opacityCurve = Interval(0.0, 0.35, curve: Curves.easeInOut);
        return Opacity(
          opacity: opacityCurve.transform(percentageComplete),
          child: CupertinoActivityIndicator.partiallyRevealed(
            radius: radius,
            progress: percentageComplete,
          ),
        );
      case RefreshIndicatorMode.armed:
      case RefreshIndicatorMode.refresh:
        return CupertinoActivityIndicator(radius: radius);
      case RefreshIndicatorMode.done:
        return CupertinoActivityIndicator(radius: radius * percentageComplete);
      case RefreshIndicatorMode.inactive:
        return const SizedBox.shrink();
    }
  }
}
