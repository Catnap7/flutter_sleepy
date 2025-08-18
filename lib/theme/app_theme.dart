// - Material 3, seed-based ColorScheme
// - Custom design tokens via ThemeExtension (spacing, radii)
// - Opinionated defaults for buttons, inputs, cards, app bar, nav bar

import 'package:flutter/material.dart';
import 'package:flutter_sleepy/core/theme/color_schemes.dart';
import 'package:flutter_sleepy/core/theme/text_theme.dart';
import 'package:flutter_sleepy/core/theme/spacing.dart';

enum SoundAccent { rainy, waves, campfire, pinknoise }

// Design tokens and schemes are now provided via core/theme/*

class AppTheme {
  // New: build everything using an arbitrary ColorScheme
  static ThemeData fromScheme(ColorScheme cs) => _baseWithScheme(cs);

  static ThemeData light() => _baseWithScheme(AppColors.light);

  static ThemeData dark() => _baseWithScheme(AppColors.dark);

  static ThemeData sleepLight() => _baseWithScheme(AppSleepColors.light);

  static ThemeData sleepDark() => _baseWithScheme(AppSleepColors.dark);

  static ThemeData _baseWithScheme(ColorScheme cs) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: cs.brightness,
    );

    final tt = AppTypography.textTheme(base.textTheme);

    return base.copyWith(
      textTheme: tt,
      scaffoldBackgroundColor: cs.surface,
      extensions: const [AppSpacing(), AppRadii()],

      // AppBar
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: tt.titleLarge,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(const AppRadii().md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(const AppRadii().md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(const AppRadii().sm),
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: cs.surfaceTint.withAlpha(80),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(const AppRadii().md),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(const AppRadii().md),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(const AppRadii().md),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),

      // Cards
      cardTheme: base.cardTheme.copyWith(
        color: cs.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(const AppRadii().lg),
        ),
      ),

      // Navigation Bar (bottom)
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 64,
        indicatorColor: cs.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return TextStyle(fontWeight: sel ? FontWeight.w600 : FontWeight.w500);
        }),
      ),

      // Sliders
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.primary.withAlpha(50),
        thumbColor: cs.primary,
        overlayColor: cs.primary.withAlpha(40),
      ),

      // Chips
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(const AppRadii().sm),
        ),
      ),

      // Dialogs / BottomSheets
      dialogTheme: base.dialogTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(const AppRadii().lg),
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(const AppRadii().lg),
          ),
        ),
        showDragHandle: true,
      ),
    );
  }
}

// ===== Convenience extensions =====
extension SpacingX on BuildContext {
  AppSpacing get sp => Theme.of(this).extension<AppSpacing>()!;

  AppRadii get radii => Theme.of(this).extension<AppRadii>()!;
}

/// Helpers to map a sound title/key to an accent and to a seed color.
class AppSoundAccent {
  static SoundAccent fromTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.contains('wave')) return SoundAccent.waves;
    if (t.replaceAll(' ', '') == 'campfire') return SoundAccent.campfire;
    if (t.contains('rainy')) return SoundAccent.rainy;
    return SoundAccent.pinknoise;
  }

  /// Base (seed) colors for each sound. Tuned to be calm at night.
  static Color seed(SoundAccent a) {
    switch (a) {
      case SoundAccent.rainy:
        return const Color(0xFF6FA7FF); // gentle rainy blue
      case SoundAccent.waves:
        return const Color(0xFF00C2B8); // aqua/teal
      case SoundAccent.campfire:
        return const Color(0xFFFF8A3D); // warm fire orange
      case SoundAccent.pinknoise:
        return const Color(0xFFFFB6D5); // soft pink
    }
  }
}

extension _AppThemeAccent on ThemeData {
  BorderRadius _resolveOutlineRadius(ThemeData base) {
    final b = base.inputDecorationTheme.border;
    if (b is OutlineInputBorder) return b.borderRadius;
    return BorderRadius.circular(16);
  }

  ThemeData _overrideWithAccent(SoundAccent accent,
      {bool recolorSecondary = false}) {
    final base = this;
    final cs = colorScheme;

// Build a tiny seed scheme for the same brightness so tones are valid.
    final seed = ColorScheme.fromSeed(
      seedColor: AppSoundAccent.seed(accent),
      brightness: cs.brightness,
    );

    final next = cs.copyWith(
// Always override primary + its containers for consistent buttons/inputs.
      primary: seed.primary,
      onPrimary: seed.onPrimary,
      primaryContainer: seed.primaryContainer,
      onPrimaryContainer: seed.onPrimaryContainer,
// Optional: also recolor secondary/tertiary to lean into the mood.
      secondary: recolorSecondary ? seed.secondary : cs.secondary,
      onSecondary: recolorSecondary ? seed.onSecondary : cs.onSecondary,
      secondaryContainer:
          recolorSecondary ? seed.secondaryContainer : cs.secondaryContainer,
      onSecondaryContainer: recolorSecondary
          ? seed.onSecondaryContainer
          : cs.onSecondaryContainer,
      tertiary: recolorSecondary ? seed.tertiary : cs.tertiary,
      onTertiary: recolorSecondary ? seed.onTertiary : cs.onTertiary,
      tertiaryContainer:
          recolorSecondary ? seed.tertiaryContainer : cs.tertiaryContainer,
      onTertiaryContainer:
          recolorSecondary ? seed.onTertiaryContainer : cs.onTertiaryContainer,
    );

    final br = _resolveOutlineRadius(this);
// Most of your sub-themes already read from ColorScheme, so a simple
// copyWith is enough.
    return copyWith(
      colorScheme: next,
// Keep scaffold background tied to surface to avoid tone jumps.
      scaffoldBackgroundColor: next.surface,
// Optional: tweak slider colors to ensure coherence if you set them explicitly.
      sliderTheme: sliderTheme.copyWith(
        activeTrackColor: next.primary,
        inactiveTrackColor: next.primary.withOpacity(0.3),
        thumbColor: next.primary,
        overlayColor: next.primary.withOpacity(0.12),
      ),
// Optional: make focused input border follow the accent.
      inputDecorationTheme: inputDecorationTheme.copyWith(
        focusedBorder: OutlineInputBorder(
          borderRadius: br,
          borderSide: BorderSide(color: next.primary, width: 2),
        ),
      ),
    );
  }
}

class AppThemeAccentAPI {
  /// Public API to generate an accented theme from an existing ThemeData.
  static ThemeData withSoundAccent(ThemeData base, SoundAccent accent,
      {bool recolorSecondary = false}) {
    return base._overrideWithAccent(accent, recolorSecondary: recolorSecondary);
  }
}

// Convenience re-export on your existing AppTheme class (optional):
extension AppThemeX on AppTheme {
  static ThemeData withSoundAccent(
    ThemeData base,
    SoundAccent accent, {
    bool recolorSecondary = false,
  }) {
    return AppThemeAccentAPI.withSoundAccent(
      base,
      accent,
      recolorSecondary: recolorSecondary,
    );
  }
}
