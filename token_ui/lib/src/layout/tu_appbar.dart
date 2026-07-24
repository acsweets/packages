import 'package:flutter/material.dart';

import '../theme/tu_extensions.dart';
import 'tu_back_button.dart';

/// App bar using [TuTheme] tokens. Back uses [onTapBack] or [Navigator.maybePop].
class TuAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TuAppBar({
    super.key,
    this.title,
    this.titleText,
    this.actions,
    this.leading,
    this.leadingWidth,
    this.centerTitle,
    this.backgroundColor,
    this.surfaceTintColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.titleSpacing,
    this.bottom,
    this.toolbarHeight,
    this.hideBack,
    this.backBackgroundColor,
    this.hideBorder,
    this.onTapBack,
    this.actionsPadding,
  });

  final Widget? title;
  final String? titleText;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final double? titleSpacing;
  final PreferredSizeWidget? bottom;
  final double? toolbarHeight;
  final bool? hideBack;
  final Color? backBackgroundColor;
  final bool? hideBorder;
  final VoidCallback? onTapBack;
  final EdgeInsetsGeometry? actionsPadding;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final canPop = navigator.canPop();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: _buildTitleText(context),
      actions: actions,
      leading: switch ((leading, hideBack ?? false, canPop)) {
        (final w?, _, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 32.aw),
            w,
          ],
        ),
        (_, false, true) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  (onTapBack ?? () => Navigator.of(context).maybePop()).call();
                },
                behavior: HitTestBehavior.opaque,
                child: const SizedBox.expand(),
              ),
            ),
            TuBackButton(
              onTap: onTapBack,
              size: backgroundColor != null ? 66.aw : null,
              backgroundColor: backBackgroundColor,
            ),
          ],
        ),
        _ => null,
      },
      leadingWidth: leadingWidth ?? 80.aw,
      centerTitle: centerTitle,
      actionsPadding: actionsPadding ?? EdgeInsets.symmetric(horizontal: 28.aw),
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      surfaceTintColor: surfaceTintColor ?? Colors.transparent,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      titleSpacing: titleSpacing ?? 20.aw,
      bottom: bottom,
      toolbarHeight: toolbarHeight,
      automaticallyImplyLeading: false,
      shape: (hideBorder ?? true)
          ? null
          : Border(
              bottom: BorderSide(color: colorScheme.outline, width: 1.aw),
            ),
    );
  }

  Widget? _buildTitleText(BuildContext context) {
    if (title != null) {
      return title;
    }
    if (titleText case final text? when text.isNotEmpty) {
      return Text(text, style: context.styles.title[4]);
    }
    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    (toolbarHeight ?? kToolbarHeight) + (bottom?.preferredSize.height ?? 0.0),
  );
}
