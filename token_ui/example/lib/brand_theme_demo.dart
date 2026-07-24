import 'package:flutter/material.dart';
import 'package:token_ui/token_ui.dart';

/// Sample brand palette for the "custom Token" demo.
abstract final class BrandColors {
  static final light = TuColors(
    mode: ThemeMode.light,
    bg: const TuBgColors(
      page: Color(0xFFFFF8F0),
      primary: Color(0xFFFFF1E0),
      secondary: Color(0xFFFFE4C7),
      component: Color(0xFFFFD6A8),
      inputfield: Color(0xFFFFF8F0),
    ),
    component: const TuComponentColors(
      stroke: Color(0xFFD4A574),
      border: Color(0xFF8B5E3C),
    ),
    mask: TuMaskColors(
      light: const Color(0xFFFFF8F0).withValues(alpha: 0.3),
      primary: const Color(0xFFFFF8F0).withValues(alpha: 0.6),
      heavy: const Color(0xFFFFF8F0).withValues(alpha: 0.8),
    ),
    text: const TuTextColors(
      primary: Color(0xFF3B2A1A),
      secondary1: Color(0xFF6B4F3A),
      secondary2: Color(0xFF8B5E3C),
      secondary3: Color(0xFFA67C52),
      placeholder: Color(0xFFC4A484),
      invert: Color(0xFFFFF8F0),
      link: Color(0xFFC45C26),
      highlight: Color(0xFFE8A838),
    ),
    button: const TuButtonColors(
      primary: Color(0xFF3B2A1A),
      secondary: Color(0xFFFFD6A8),
      neutral: Color(0xFFC45C26),
    ),
    error: const TuErrorColors(
      primary: Color(0xFFC62828),
      secondary: Color(0xFFEF5350),
    ),
    success: const Color(0xFF2E7D32),
  );

  static final dark = TuColors(
    mode: ThemeMode.dark,
    bg: const TuBgColors(
      page: Color(0xFF1A120B),
      primary: Color(0xFF241810),
      secondary: Color(0xFF2E2016),
      component: Color(0xFF3D2B1C),
      inputfield: Color(0xFF241810),
    ),
    component: const TuComponentColors(
      stroke: Color(0xFF8B5E3C),
      border: Color(0xFFD4A574),
    ),
    mask: TuMaskColors(
      light: const Color(0xFF1A120B).withValues(alpha: 0.3),
      primary: const Color(0xFF1A120B).withValues(alpha: 0.6),
      heavy: const Color(0xFF1A120B).withValues(alpha: 0.8),
    ),
    text: const TuTextColors(
      primary: Color(0xFFFFF1E0),
      secondary1: Color(0xFFD4A574),
      secondary2: Color(0xFFE8C9A8),
      secondary3: Color(0xFFFFD6A8),
      placeholder: Color(0xFF8B5E3C),
      invert: Color(0xFF241810),
      link: Color(0xFFFF8A50),
      highlight: Color(0xFFFFC107),
    ),
    button: const TuButtonColors(
      primary: Color(0xFFFFF1E0),
      secondary: Color(0xFF3D2B1C),
      neutral: Color(0xFFC45C26),
    ),
    error: const TuErrorColors(
      primary: Color(0xFFEF5350),
      secondary: Color(0xFFE57373),
    ),
    success: const Color(0xFF66BB6A),
  );
}
