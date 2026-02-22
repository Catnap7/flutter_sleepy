import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_sleepy/constants/notification_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> initializeService() async {
  try {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelTitle,
      description: 'Playback notification shown while Sleepy is playing.',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          // Use the app launcher icon; avoids missing-resource crashes.
          android: AndroidInitializationSettings('ic_launcher'),
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
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'Sleepy',
        initialNotificationContent: 'Playing in background',
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
    debugPrint('Background service initialization failed: $e');
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

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });

    service.on('updateNotification').listen((event) async {
      final String? title = (event?["title"])?.toString();
      final String? content = (event?["content"])?.toString();
      if (title != null && content != null) {
        await service.setForegroundNotificationInfo(
            title: title, content: content);
      }
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
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
