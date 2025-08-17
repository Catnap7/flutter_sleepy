import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sleepy/constants/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  try {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      NOTIFICATION_CHANNEL_ID,
      NOTIFICATION_CHANNEL_TITLE,
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('ic_bg_service_small'),
        ),
      );
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: NOTIFICATION_CHANNEL_ID,
        initialNotificationTitle: 'Sleepy Audio',
        initialNotificationContent: 'Initializing audio playback service',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.mediaPlayback],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  } catch (e) {
    debugPrint('백그라운드 서비스 초기화 실패: $e');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final log = preferences.getStringList('log') ?? <String>[];
  log.add(DateTime.now().toIso8601String());
  await preferences.setStringList('log', log);

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("hello", "world");

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool customNotificationActive = false;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('updateNotification').listen((event) async {
      final String? title = (event?["title"])?.toString();
      final String? content = (event?["content"])?.toString();
      if (title != null && content != null) {
        customNotificationActive = true;
        await service.setForegroundNotificationInfo(title: title, content: content);
      }
    });

    service.on('resetNotification').listen((event) async {
      customNotificationActive = false;
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        if (!customNotificationActive) {
          // Keep a lightweight heartbeat without overriding custom content
          await service.setForegroundNotificationInfo(
            title: "Sleepy Audio",
            content: "Ready in background • ${DateTime.now().toLocal().toIso8601String()}",
          );
        }
      }
    }

    debugPrint('FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');

    final deviceInfo = DeviceInfoPlugin();
    String? device;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      device = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      device = iosInfo.model;
    }

    service.invoke(
      'update',
      {
        "current_date": DateTime.now().toIso8601String(),
        "device": device,
      },
    );
  });
}

Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();
  var isRunning = await service.isRunning();
  if (!isRunning) {
    service.startService();
  }
  service.invoke('setAsForeground');
}