import 'package:flutter/material.dart';

import 'tu_colors.dart';
import 'tu_text_styles.dart';

/// Resolved theme data used by Tu* widgets.
class TuThemeData {
  const TuThemeData({
    required this.mode,
    required this.colors,
    required this.textStyles,
  });

  final ThemeMode mode;
  final TuColors colors;
  final TuTextStyles textStyles;

  factory TuThemeData.builtIn({
    ThemeMode mode = ThemeMode.dark,
    TuColors? colors,
    TuTextStyles? textStyles,
  }) {
    final resolvedMode = mode == ThemeMode.system ? ThemeMode.dark : mode;
    return TuThemeData(
      mode: resolvedMode,
      colors: colors ?? TuColors.builtIn(resolvedMode),
      textStyles: textStyles ?? TuTextStyles.builtIn(),
    );
  }
}

/// Provides [TuColors] / [TuTextStyles] to descendants.
///
/// If omitted, widgets fall back to [TuThemeData.builtIn].
class TuTheme extends InheritedWidget {
  const TuTheme({
    super.key,
    this.mode = ThemeMode.dark,
    this.colors,
    this.textStyles,
    required super.child,
  });

  final ThemeMode mode;
  final TuColors? colors;
  final TuTextStyles? textStyles;

  TuThemeData get data => TuThemeData.builtIn(
    mode: mode,
    colors: colors,
    textStyles: textStyles,
  );

  static TuTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TuTheme>();
  }

  /// Host theme if present, otherwise built-in dark defaults.
  static TuThemeData resolve(BuildContext context) {
    final provided = maybeOf(context);
    if (provided != null) {
      return provided.data;
    }
    return TuThemeData.builtIn();
  }

  @override
  bool updateShouldNotify(covariant TuTheme oldWidget) {
    return mode != oldWidget.mode ||
        colors != oldWidget.colors ||
        textStyles != oldWidget.textStyles;
  }
}
