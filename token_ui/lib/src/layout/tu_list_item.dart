import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';

/// Single-line list item with optional chevron.
class TuListItem extends StatelessWidget {
  const TuListItem({
    super.key,
    required this.leading,
    this.center,
    this.trailing,
    this.spacing,
    this.showChevron = false,
    this.height,
    this.onTap,
  });

  factory TuListItem.menu({
    Key? key,
    required String title,
    Widget? trailing,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return TuListItem(
      key: key,
      height: 70.aw,
      spacing: 32.aw,
      leading: _TuMenuLabel(title),
      center: const Spacer(),
      trailing: trailing,
      onTap: onTap,
      showChevron: showChevron,
    );
  }

  final Widget leading;
  final Widget? center;
  final Widget? trailing;
  final double? spacing;
  final bool showChevron;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            leading,
            if (center case final center?) ...[
              SizedBox(width: spacing),
              center,
            ],
            if (trailing case final trailing?) ...[
              SizedBox(width: spacing),
              trailing,
            ],
            if (showChevron) ...[
              if (center != null || trailing != null) SizedBox(width: 16.aw),
              Icon(Icons.chevron_right, size: 36.aw),
            ],
          ],
        ),
      ),
    );
  }
}

class _TuMenuLabel extends StatelessWidget {
  const _TuMenuLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: context.styles.body[1], maxLines: 1);
  }
}
