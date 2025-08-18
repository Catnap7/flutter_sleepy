import 'package:flutter/material.dart';

/// App color schemes (seed-based Material 3)
class AppColors {
  // Brand seed (kept from existing theme for no visual changes)
  static const Color seed = Color(0xFFC20000);

  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFF7C4DFF),
    tertiary: const Color(0xFFFFB300),
    error: const Color(0xFFE53935),
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: const Color(0xFFB388FF),
    tertiary: const Color(0xFFFFCA28),
    error: const Color(0xFFFF5370),
    surface: const Color(0xFF0D1117),
  );
}

/// Sleep-optimized palette: muted, warm, low-stimulation
class AppSleepColors {
  static const Color seed = Color(0xFF424B77); // muted soft purple

  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF1A080D),
    secondary: const Color(0xFF9B8EC1),
    tertiary: const Color(0xFFBFAF9F),
    error: const Color(0xFFCF6679),
    surface: const Color(0xFFF5F3F8),
    surfaceTint: const Color(0xFF6E5AA8),
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFFB8A7E6),
    secondary: const Color(0xFFD3C8F0),
    tertiary: const Color(0xFFC9BEB3),
    error: const Color(0xFFFF8A80),
    surface: const Color(0xFF0E1016),
    surfaceTint: const Color(0xFFB8A7E6),
  );
}

