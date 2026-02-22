import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BatteryOptimizationHandler {
  static const String _educationShownKey = 'battery_opt_education_shown_v1';

  static Future<bool> isSupported() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    return deviceInfo.version.sdkInt >= 23;
  }

  static Future<bool> isIgnored() async {
    if (!await isSupported()) {
      return true;
    }
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  static Future<bool> shouldShowEducation() async {
    if (!await isSupported()) {
      return false;
    }
    if (await isIgnored()) {
      return false;
    }
    final preferences = await SharedPreferences.getInstance();
    final shown = preferences.getBool(_educationShownKey) ?? false;
    return !shown;
  }

  static Future<void> markEducationShown() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_educationShownKey, true);
  }

  static Future<void> requestIgnoreBatteryOptimization() async {
    if (!await isSupported()) {
      return;
    }
    await Permission.ignoreBatteryOptimizations.request();
  }
}
