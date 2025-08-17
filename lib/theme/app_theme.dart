// - Material 3, seed-based ColorScheme
// - Custom design tokens via ThemeExtension (spacing, radii)
// - Opinionated defaults for buttons, inputs, cards, app bar, nav bar

import 'package:flutter/material.dart';

// ===== Design Tokens (ThemeExtensions) =====
class AppSpacing extends ThemeExtension<AppSpacing> {
  final double xs; // 4
  final double sm; // 8
  final double md; // 12
  final double lg; // 16
  final double xl; // 24
  final double xxl; // 32

  const AppSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.xxl = 32,
  });

  @override
  AppSpacing copyWith(
          {double? xs,
          double? sm,
          double? md,
          double? lg,
          double? xl,
          double? xxl}) =>
      AppSpacing(
          xs: xs ?? this.xs,
          sm: sm ?? this.sm,
          md: md ?? this.md,
          lg: lg ?? this.lg,
          xl: xl ?? this.xl,
          xxl: xxl ?? this.xxl);

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      xs: lerpDouble(xs, other.xs, t),
      sm: lerpDouble(sm, other.sm, t),
      md: lerpDouble(md, other.md, t),
      lg: lerpDouble(lg, other.lg, t),
      xl: lerpDouble(xl, other.xl, t),
      xxl: lerpDouble(xxl, other.xxl, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

class AppRadii extends ThemeExtension<AppRadii> {
  final double sm; // 8
  final double md; // 16
  final double lg; // 24

  const AppRadii({this.sm = 8, this.md = 16, this.lg = 24});

  @override
  AppRadii copyWith({double? sm, double? md, double? lg}) =>
      AppRadii(sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg);

  @override
  AppRadii lerp(ThemeExtension<AppRadii>? other, double t) {
    if (other is! AppRadii) return this;
    return AppRadii(
      sm: AppSpacing.lerpDouble(sm, other.sm, t),
      md: AppSpacing.lerpDouble(md, other.md, t),
      lg: AppSpacing.lerpDouble(lg, other.lg, t),
    );
  }
}

// ===== Color Schemes (seed based) =====
class AppColors {
  // Vibrant, modern aqua as the primary brand seed (Day mode)
  static const Color seed = Color(0xFF00C2B8);

  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    secondary: const Color(0xFF7C4DFF), // Vibrant violet
    tertiary: const Color(0xFFFFB300), // Warm amber
    error: const Color(0xFFE53935),
  );

  static final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  ).copyWith(
    secondary: const Color(0xFFB388FF), // Softer violet for dark
    tertiary: const Color(0xFFFFCA28), // Amber for dark
    error: const Color(0xFFFF5370),
    surface: const Color(0xFF0D1117),
  );
}

// Sleep-optimized palette: muted, warm, low-stimulation
class AppSleepColors {
  static const Color seed = Color(0xFF5B4B8A); // muted soft purple

  static final ColorScheme light = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF6E5AA8), // softened primary
    secondary: const Color(0xFF9B8EC1), // mauve accent
    tertiary: const Color(0xFFBFAF9F), // warm gray accent
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

// ===== Typography helper (uses default Material if GoogleFonts not installed) =====
class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    // If you want Pretendard or NotoSansKR, add google_fonts and replace below.
    // final t = GoogleFonts.pretendardTextTheme(base);
    final t = base;
    return t.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.3),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.3),
      bodySmall: base.bodySmall?.copyWith(height: 1.3),
    );
  }
}

// ===== Theming Entrypoints =====
class AppTheme {
  static ThemeData light() {
    final cs = AppColors.light;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      brightness: Brightness.light,
    );

    return base.copyWith(
      textTheme: AppTypography.textTheme(base.textTheme),
      scaffoldBackgroundColor: cs.surface,
      extensions: const [AppSpacing(), AppRadii()],

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.textTheme(base.textTheme).titleLarge,
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(const AppRadii().md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(const AppRadii().md)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(const AppRadii().sm)),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
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
      cardTheme: CardThemeData(
        color: cs.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(const AppRadii().lg)),
      ),

      // Navigation Bar (bottom)
      navigationBarTheme: NavigationBarThemeData(
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
            borderRadius: BorderRadius.circular(const AppRadii().sm)),
      ),

      // Dialogs/BottomSheets
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(const AppRadii().lg)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(const AppRadii().lg)),
        ),
        showDragHandle: true,
      ),
    );
  }

  static ThemeData dark() {
    final cs = AppColors.dark;

    return light().copyWith(
      colorScheme: cs,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: cs.surface,
    );
  }

  // Sleep mode variants (muted, warm tones optimized for bedtime)
  static ThemeData sleepLight() {
    final cs = AppSleepColors.light;
    final base = light();
    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
    );
  }

  static ThemeData sleepDark() {
    final cs = AppSleepColors.dark;
    final base = dark();
    return base.copyWith(
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
    );
  }
}

// ===== Convenience extensions =====
extension SpacingX on BuildContext {
  AppSpacing get sp => Theme.of(this).extension<AppSpacing>()!;

  AppRadii get radii => Theme.of(this).extension<AppRadii>()!;
}



// ===== Example usage widget =====
class ThemedExample extends StatelessWidget {
  const ThemedExample({super.key});

  @override
  Widget build(BuildContext context) {
    final sp = context.sp;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Redesign Starter')),
      body: Padding(
        padding: EdgeInsets.all(sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hello, JAEWOO',
                style: Theme.of(context).textTheme.headlineLarge),
            SizedBox(height: sp.lg),
            TextField(decoration: const InputDecoration(hintText: 'Search…')),
            SizedBox(height: sp.lg),
            Card(
              child: Padding(
                padding: EdgeInsets.all(sp.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick actions',
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: sp.sm),
                    Wrap(spacing: sp.sm, runSpacing: sp.sm, children: [
                      FilledButton(
                          onPressed: () {}, child: const Text('Primary')),
                      ElevatedButton(
                          onPressed: () {}, child: const Text('Elevated')),
                      OutlinedButton(
                          onPressed: () {}, child: const Text('Outlined')),
                      TextButton(onPressed: () {}, child: const Text('Text')),
                    ]),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.all(sp.lg),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(context.radii.lg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  SizedBox(width: sp.md),
                  const Expanded(
                      child: Text(
                          'Tip: swap your seed color to instantly rebrand.')),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Me'),
        ],
      ),
    );
  }
}
