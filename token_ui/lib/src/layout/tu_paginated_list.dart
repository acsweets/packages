import 'package:flutter/cupertino.dart';

import '../theme/tu_extensions.dart';

/// Paginated list as a [SliverList]. Host must detect scroll-end for load-more.
class TuPaginatedList extends StatelessWidget {
  const TuPaginatedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.hasMore,
    required this.isLoadingMore,
    this.loadingWidget,
    this.noMoreWidget,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final bool hasMore;
  final bool isLoadingMore;
  final Widget? loadingWidget;
  final Widget? noMoreWidget;

  @override
  Widget build(BuildContext context) {
    final hasFooter = isLoadingMore || (!hasMore && noMoreWidget != null);
    final totalCount = itemCount + (hasFooter ? 1 : 0);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == itemCount && hasFooter) {
          return _buildFooter();
        }
        return itemBuilder(context, index);
      }, childCount: totalCount),
    );
  }

  Widget _buildFooter() {
    if (isLoadingMore) {
      return loadingWidget ?? _defaultLoadingWidget();
    }
    return noMoreWidget ?? const SizedBox.shrink();
  }

  Widget _defaultLoadingWidget() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.aw),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
