import 'package:flutter/material.dart';

/// Square icon button. Icon is fitted with [BoxFit.contain].
class TuIconButton extends StatelessWidget {
  const TuIconButton({
    super.key,
    required this.icon,
    required this.iconSize,
    this.size,
    this.backgroundColor,
    this.onTap,
  }) : assert(
         size == null || size >= iconSize,
         'size must be greater than or equal to iconSize',
       );

  final Widget icon;
  final double iconSize;

  /// Hit area size. Null → fill parent with 1:1 aspect ratio.
  final double? size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget widget = Container(
      alignment: Alignment.center,
      width: iconSize,
      height: iconSize,
      child: FittedBox(fit: BoxFit.contain, child: icon),
    );

    if (size case final sz?) {
      widget = Container(
        width: sz,
        height: sz,
        alignment: Alignment.center,
        child: widget,
      );
    } else {
      widget = AspectRatio(aspectRatio: 1.0, child: widget);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: widget,
      ),
    );
  }
}
