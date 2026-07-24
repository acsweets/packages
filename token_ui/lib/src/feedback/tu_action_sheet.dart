import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

class TuActionSheetItem {
  const TuActionSheetItem({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// Bottom action sheet with items + Cancel.
class TuActionSheet extends StatelessWidget {
  const TuActionSheet._({required this.items});

  final List<TuActionSheetItem> items;

  static void show(
    BuildContext context, {
    required List<TuActionSheetItem> items,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: slideAnimation,
                child: TuActionSheet._(items: items),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.styles;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg.secondary,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40.ar),
            topRight: Radius.circular(40.ar),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 64.aw),
            for (var i = 0; i < items.length; i++) ...[
              _buildItem(context, items[i]),
              SizedBox(height: 32.aw),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 38.aw),
                child: Divider(height: 1, color: colors.component.stroke),
              ),
              SizedBox(height: 32.aw),
            ],
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Cancel',
                    style: styles.body[2].copyWith(color: colors.error.primary),
                  ),
                ),
              ),
            ),
            SizedBox(height: 64.aw),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, TuActionSheetItem item) {
    final colors = context.colors;
    final styles = context.styles;
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        child: Center(
          child: Text(
            item.label,
            style: item.isDestructive
                ? styles.body[2].copyWith(color: colors.error.primary)
                : styles.body[2],
          ),
        ),
      ),
    );
  }
}
