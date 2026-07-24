import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

class TuActionMenuItem {
  const TuActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Overlay action menu (e.g. long-press). Does not affect keyboard.
class TuActionMenu {
  TuActionMenu._();

  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required Offset position,
    required Size anchorSize,
    required List<TuActionMenuItem> items,
    bool alignRight = false,
    Color backgroundColor = const Color(0xFF2C2C2C),
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
    double? menuHeight,
    double? itemWidth,
  }) {
    dismiss();

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _TuActionMenuOverlay(
        position: position,
        anchorSize: anchorSize,
        items: items,
        alignRight: alignRight,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        textColor: textColor,
        menuHeight: menuHeight,
        itemWidth: itemWidth,
        onDismiss: dismiss,
      ),
    );

    final entry = _overlayEntry;
    if (entry != null) {
      overlay.insert(entry);
    }
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _TuActionMenuOverlay extends StatelessWidget {
  const _TuActionMenuOverlay({
    required this.position,
    required this.anchorSize,
    required this.items,
    required this.alignRight,
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
    required this.onDismiss,
    this.menuHeight,
    this.itemWidth,
  });

  final Offset position;
  final Size anchorSize;
  final List<TuActionMenuItem> items;
  final bool alignRight;
  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
  final double? menuHeight;
  final double? itemWidth;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveItemWidth = itemWidth ?? 50.aw;
    final effectiveMenuHeight = menuHeight ?? 90.aw;
    final menuWidth = _estimateMenuWidth(effectiveItemWidth);
    final menuTop = position.dy + anchorSize.height + 15.aw;

    double menuLeft;
    if (alignRight) {
      menuLeft = position.dx + anchorSize.width - menuWidth;
      if (menuLeft < 16) menuLeft = 16;
    } else {
      menuLeft = position.dx;
      if (menuLeft + menuWidth > screenWidth - 16) {
        menuLeft = screenWidth - 16 - menuWidth;
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.3)),
          ),
        ),
        Positioned(
          left: menuLeft,
          top: menuTop,
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: effectiveMenuHeight,
              padding: EdgeInsets.symmetric(horizontal: 12.aw, vertical: 8.aw),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8.ar),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildMenuItems(effectiveItemWidth),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _estimateMenuWidth(double effectiveItemWidth) {
    final itemCount = items.isEmpty ? 1 : items.length;
    return (itemCount * effectiveItemWidth) + (itemCount - 1) * 8.aw + 32.aw;
  }

  List<Widget> _buildMenuItems(double effectiveItemWidth) {
    final menuItems = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        menuItems.add(SizedBox(width: 8.aw));
      }
      final item = items[i];
      menuItems.add(
        _buildMenuItem(
          icon: item.icon,
          label: item.label,
          onTap: () {
            onDismiss();
            item.onTap();
          },
          itemWidth: effectiveItemWidth,
        ),
      );
    }
    return menuItems;
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required double itemWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: itemWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 32.aw),
            SizedBox(height: 4.aw),
            Text(
              label,
              style: TextStyle(color: textColor, fontSize: 20.asp),
            ),
          ],
        ),
      ),
    );
  }
}
