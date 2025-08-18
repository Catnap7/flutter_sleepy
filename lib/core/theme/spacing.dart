import 'package:flutter/material.dart';

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
  AppSpacing copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return AppSpacing(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

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
  AppRadii copyWith({double? sm, double? md, double? lg}) {
    return AppRadii(sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg);
  }

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

