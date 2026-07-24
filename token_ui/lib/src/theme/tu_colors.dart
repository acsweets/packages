import 'package:flutter/material.dart';

/// Semantic color tokens for [TuTheme].
///
/// Hosts may supply a custom instance; otherwise [TuColors.builtIn] is used.
class TuColors {
  const TuColors({
    required this.mode,
    required this.bg,
    required this.component,
    required this.mask,
    required this.text,
    required this.button,
    required this.error,
    required this.success,
  });

  /// Built-in light or dark palette (aligned with Nocnok product tokens).
  factory TuColors.builtIn(ThemeMode mode) {
    assert(
      mode == ThemeMode.light || mode == ThemeMode.dark,
      'TuColors.builtIn only supports light or dark',
    );
    return mode == ThemeMode.dark ? _dark : _light;
  }

  final ThemeMode mode;
  final TuBgColors bg;
  final TuComponentColors component;
  final TuMaskColors mask;
  final TuTextColors text;
  final TuButtonColors button;
  final TuErrorColors error;
  final Color success;

  static final _dark = TuColors(
    mode: ThemeMode.dark,
    bg: const TuBgColors(
      page: Color(0xFF000000),
      primary: Color(0xFF171717),
      secondary: Color(0xFF262626),
      component: Color(0xFF404040),
      inputfield: Color(0xFF18181B),
    ),
    component: const TuComponentColors(
      stroke: Color(0xFF737373),
      border: Color(0xFFD4D4D4),
    ),
    mask: TuMaskColors(
      light: const Color(0xFF000000).withValues(alpha: 0.30),
      primary: const Color(0xFF000000).withValues(alpha: 0.60),
      heavy: const Color(0xFF000000).withValues(alpha: 0.80),
    ),
    text: const TuTextColors(
      primary: Color(0xFFFFFFFF),
      secondary1: Color(0xFFA3A3A3),
      secondary2: Color(0xFFD4D4D4),
      secondary3: Color(0xFFD4D4D8),
      placeholder: Color(0xFF525252),
      invert: Color(0xFF262626),
      link: Color(0xFF3B82F6),
      highlight: Color(0xFFFDE047),
    ),
    button: const TuButtonColors(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFF404040),
      neutral: Color(0xFF2563EB),
    ),
    error: const TuErrorColors(
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFFB7185),
    ),
    success: const Color(0xFF4ADE80),
  );

  static final _light = TuColors(
    mode: ThemeMode.light,
    bg: const TuBgColors(
      page: Color(0xFFFFFFFF),
      primary: Color(0xFFFAFAFA),
      secondary: Color(0xFFF5F5F5),
      component: Color(0xFFE5E5E5),
      inputfield: Color(0xFFF4F4F5),
    ),
    component: const TuComponentColors(
      stroke: Color(0xFFA3A3A3),
      border: Color(0xFF525252),
    ),
    mask: TuMaskColors(
      light: const Color(0xFFFFFFFF).withValues(alpha: 0.30),
      primary: const Color(0xFFFFFFFF).withValues(alpha: 0.60),
      heavy: const Color(0xFFFFFFFF).withValues(alpha: 0.80),
    ),
    text: const TuTextColors(
      primary: Color(0xFF000000),
      secondary1: Color(0xFF525252),
      secondary2: Color(0xFF404040),
      secondary3: Color(0xFF3F3F46),
      placeholder: Color(0xFFA3A3A3),
      invert: Color(0xFFFAFAFA),
      link: Color(0xFF2563EB),
      highlight: Color(0xFFCA8A04),
    ),
    button: const TuButtonColors(
      primary: Color(0xFF000000),
      secondary: Color(0xFFE5E5E5),
      neutral: Color(0xFF2563EB),
    ),
    error: const TuErrorColors(
      primary: Color(0xFFE11D48),
      secondary: Color(0xFFFB7185),
    ),
    success: const Color(0xFF16A34A),
  );
}

class TuBgColors {
  const TuBgColors({
    required this.page,
    required this.primary,
    required this.secondary,
    required this.component,
    required this.inputfield,
  });

  final Color page;
  final Color primary;
  final Color secondary;
  final Color component;
  final Color inputfield;
}

class TuComponentColors {
  const TuComponentColors({required this.stroke, required this.border});

  final Color stroke;
  final Color border;
}

class TuMaskColors {
  const TuMaskColors({
    required this.light,
    required this.primary,
    required this.heavy,
  });

  final Color light;
  final Color primary;
  final Color heavy;
}

class TuTextColors {
  const TuTextColors({
    required this.primary,
    required this.secondary1,
    required this.secondary2,
    required this.secondary3,
    required this.placeholder,
    required this.invert,
    required this.link,
    required this.highlight,
  });

  final Color primary;
  final Color secondary1;
  final Color secondary2;
  final Color secondary3;
  final Color placeholder;
  final Color invert;
  final Color link;
  final Color highlight;
}

class TuButtonColors {
  const TuButtonColors({
    required this.primary,
    required this.secondary,
    required this.neutral,
  });

  final Color primary;
  final Color secondary;
  final Color neutral;
}

class TuErrorColors {
  const TuErrorColors({required this.primary, required this.secondary});

  final Color primary;
  final Color secondary;
}
