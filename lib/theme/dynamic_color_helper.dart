import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';

/// Fetches dynamic color schemes on Android 12+ (and supported platforms).
/// Returns nulls if not available.
Future<(ColorScheme?, ColorScheme?)> fetchDynamicSchemes() async {
  final corePalette = await DynamicColorPlugin.getCorePalette();
  if (corePalette == null) return (null, null);
  final light = corePalette.toColorScheme();
  final dark = corePalette.toColorScheme(brightness: Brightness.dark);
  return (light, dark);
}

