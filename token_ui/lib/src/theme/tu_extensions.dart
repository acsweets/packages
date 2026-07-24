import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'tu_colors.dart';
import 'tu_text_styles.dart';
import 'tu_theme.dart';

export 'package:flutter_screenutil/flutter_screenutil.dart';

extension TuTextStyleColor on TextStyle {
  /// Combines this style with [color] (`style + colors.text.primary`).
  TextStyle operator +(Color? color) {
    if (color == null) {
      return this;
    }
    return copyWith(color: color);
  }

  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
}

extension TuColorOpacity on Color {
  /// Opacity rank 0–100 (`color / 50` → 50% of current alpha).
  Color operator /(int rank) {
    assert(rank >= 0 && rank <= 100, 'Opacity rank must be between 0 and 100');
    return withValues(alpha: a * rank.clamp(0, 100) / 100);
  }
}

extension TuBuildContextTheme on BuildContext {
  /// Resolved theme: host [TuTheme] or built-in defaults.
  TuThemeData get tuTheme => TuTheme.resolve(this);

  TuColors get colors => tuTheme.colors;

  TuTextStyles get styles => tuTheme.textStyles;
}

extension TuStateTheme<T extends StatefulWidget> on State<T> {
  TuThemeData get tuTheme => TuTheme.resolve(context);

  TuColors get colors => tuTheme.colors;

  TuTextStyles get styles => tuTheme.textStyles;
}

/// Adaptive sizes. Uses ScreenUtil when initialized; otherwise returns raw values.
extension TuAdaptiveSize on num {
  double get aw => _suOrRaw((n) => n.w);
  double get ah => _suOrRaw((n) => n.w);
  double get asp => _suOrRaw((n) => n.sp);
  double get ar => _suOrRaw((n) => n.r);
  double get asw => _suOrRaw((n) => n.sw);
  double get ash => _suOrRaw((n) => n.sh);

  double _suOrRaw(double Function(num value) scaled) {
    try {
      return scaled(this);
    } catch (_) {
      return toDouble();
    }
  }
}
