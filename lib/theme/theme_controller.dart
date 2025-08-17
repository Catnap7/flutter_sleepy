import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sleepy/theme/app_theme.dart';

/// Theme options for the app.
enum AppThemeOption {
  sleep,
  day,
  dynamic,
}

class ThemeController extends ChangeNotifier {
  static const _prefKey = 'app_theme_option_v1';
  static const _intensityKey = 'bg_intensity_v1';

  AppThemeOption _option = AppThemeOption.sleep; // default to sleep-friendly
  ThemeMode _themeMode = ThemeMode.system;
  double _bgIntensity = 1.0; // 0.5 ~ 1.5

  AppThemeOption get option => _option;
  ThemeMode get themeMode => _themeMode;
  double get bgIntensity => _bgIntensity;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final name = sp.getString(_prefKey);
    if (name != null) {
      _option = AppThemeOption.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AppThemeOption.sleep,
      );
    }
    _bgIntensity = sp.getDouble(_intensityKey) ?? 1.0;
    notifyListeners();
  }

  Future<void> setOption(AppThemeOption value) async {
    _option = value;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_prefKey, value.name);
    notifyListeners();
  }

  Future<void> setBgIntensity(double value) async {
    final v = value.clamp(0.5, 1.5);
    _bgIntensity = v;
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_intensityKey, v);
    notifyListeners();
  }

  /// Returns the ThemeData based on current selection.
  /// If option=dynamic, callers should supply dynamic schemes and fallback here.
  ThemeData resolveLight({ColorScheme? dynamicScheme}) {
    switch (_option) {
      case AppThemeOption.sleep:
        return AppTheme.sleepLight();
      case AppThemeOption.day:
        return AppTheme.light();
      case AppThemeOption.dynamic:
        return dynamicScheme != null
            ? AppTheme.fromScheme(dynamicScheme)
            : AppTheme.light();
    }
  }

  ThemeData resolveDark({ColorScheme? dynamicScheme}) {
    switch (_option) {
      case AppThemeOption.sleep:
        return AppTheme.sleepDark();
      case AppThemeOption.day:
        return AppTheme.dark();
      case AppThemeOption.dynamic:
        return dynamicScheme != null
            ? AppTheme.fromScheme(dynamicScheme)
            : AppTheme.dark();
    }
  }
}

