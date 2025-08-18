import 'package:flutter/material.dart';

class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    final t = base; // Keep default to avoid adding dependencies
    return t.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.3),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.3),
      bodySmall: base.bodySmall?.copyWith(height: 1.3),
    );
  }
}

