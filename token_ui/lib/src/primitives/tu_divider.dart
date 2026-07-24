import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Thin horizontal divider using [TuColors.component.stroke].
class TuDivider extends StatelessWidget {
  const TuDivider({
    super.key,
    this.height,
    this.thickness,
    this.indent,
    this.endIndent,
    this.color,
  });

  final double? height;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final stroke = thickness ?? 1.aw;
    return Divider(
      height: height ?? stroke,
      thickness: stroke,
      indent: indent,
      endIndent: endIndent,
      color: color ?? context.colors.component.stroke,
    );
  }
}
