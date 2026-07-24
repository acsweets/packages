import 'package:flutter/material.dart';

import 'tu_extensions.dart';

/// Typography tokens for [TuTheme].
class TuTextStyles {
  const TuTextStyles({
    this.fontFamily,
    this.display = const TuFont(
      [128, 96, 72, 64, 48, 36, 32, 28, 24, 20, 16],
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    this.special = const TuFont(
      [72, 64, 56, 48, 36, 32, 28],
      fontWeight: FontWeight.w900,
      height: 1.2,
    ),
    this.headline = const TuFont(
      [56, 48, 36, 32, 28],
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    this.title = const TuFont(
      [48, 40, 36, 32, 28, 24, 20],
      fontWeight: FontWeight.w500,
      height: 1.2,
    ),
    this.body = const TuFont(
      [32, 28, 24, 20],
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    this.meta = const TuFont(
      [32, 28, 24, 20, 16],
      fontWeight: FontWeight.w300,
      height: 1.3,
    ),
    this.link = const TuFont(
      [32, 28, 24],
      fontWeight: FontWeight.w400,
      height: 1.3,
    ),
  });

  /// Built-in typography (system font unless [fontFamily] is set).
  factory TuTextStyles.builtIn({String? fontFamily}) =>
      TuTextStyles(fontFamily: fontFamily);

  final String? fontFamily;
  final TuFont display;
  final TuFont special;
  final TuFont headline;
  final TuFont title;
  final TuFont body;
  final TuFont meta;
  final TuFont link;
}

/// A scale of [TextStyle]s addressed by 1-based index.
class TuFont {
  const TuFont(
    this.sizes, {
    required this.fontWeight,
    required this.height,
    this.fontFamily,
  });

  final List<double> sizes;
  final String? fontFamily;
  final FontWeight fontWeight;
  final double height;

  TextStyle operator [](int index) {
    assert(index > 0 && index <= sizes.length, 'Font index out of range');
    final size = (index < 1 || index > sizes.length)
        ? null
        : sizes[index - 1].asp;
    return TextStyle(
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      height: height,
      fontSize: size,
    );
  }
}
