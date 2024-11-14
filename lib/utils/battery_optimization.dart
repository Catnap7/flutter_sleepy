import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BatteryOptimizationHandler {
  static Future<void> ignoreBatteryOptimization() async {
    if (Platform.isAndroid) {
      // Android 버전 확인
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 23) { // Android 6.0 (API 23) 이상
        final status = await Permission.ignoreBatteryOptimizations.status;
        if (!status.isGranted) {
          // 배터리 최적화 무시 권한 요청
          await Permission.ignoreBatteryOptimizations.request();
        }
      }
    }
  }
}