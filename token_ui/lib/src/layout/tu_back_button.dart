import 'package:flutter/material.dart';

import '../primitives/tu_icon_button.dart';
import '../theme/tu_extensions.dart';

/// Back button. Default icon [Icons.chevron_left]; taps call [Navigator.maybePop].
class TuBackButton extends StatelessWidget {
  const TuBackButton({
    super.key,
    this.icon,
    this.iconSize,
    this.size,
    this.backgroundColor,
    this.onTap,
  });

  /// Defaults to [Icons.chevron_left].
  final Widget? icon;
  final double? iconSize;
  final double? size;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TuIconButton(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      icon: icon ?? const Icon(Icons.chevron_left),
      iconSize: iconSize ?? 36.aw,
      size: size ?? 50.aw,
      backgroundColor: backgroundColor,
    );
  }
}
