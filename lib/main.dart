import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sleepy/constants/admob_constants.dart';
import 'package:flutter_sleepy/screens/audio_home_page.dart';
import 'package:flutter_sleepy/screens/theme_settings_screen.dart';
import 'package:flutter_sleepy/services/app_open_ad_manager.dart';
import 'package:flutter_sleepy/services/background_service_stub.dart'
    if (dart.library.io) 'package:flutter_sleepy/services/background_service.dart';
import 'package:flutter_sleepy/services/metrics_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_sleepy/theme/dynamic_color_helper.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await initializeService();
    }
  } catch (e) {
    debugPrint('Failed to initialize background service: $e');
  }
  final controller = ThemeController();
  await controller.load();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await MobileAds.instance.initialize();
  }
  await MetricsService.instance.trackAppOpen();
  runApp(MyApp(controller: controller));
}

class MyApp extends StatefulWidget {
  final ThemeController controller;
  final Widget? homeOverride;
  const MyApp({
    super.key,
    required this.controller,
    this.homeOverride,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  ColorScheme? _dynLight;
  ColorScheme? _dynDark;
  final AppOpenAdManager _appOpenAdManager =
      AppOpenAdManager(adUnitId: androidAppOpenAdUnitId);
  DateTime? _lastPausedAt;

  bool get _enableAppOpenAds =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Fetch dynamic color schemes (Android 12+)
    fetchDynamicSchemes().then((schemes) {
      setState(() {
        _dynLight = schemes.$1;
        _dynDark = schemes.$2;
      });
    });
    widget.controller.addListener(_onThemeChanged);
    if (_enableAppOpenAds) {
      _appOpenAdManager.loadAd(showOnLoad: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_enableAppOpenAds) {
      _appOpenAdManager.dispose();
    }
    widget.controller.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enableAppOpenAds) {
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastPausedAt = DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final lastPausedAt = _lastPausedAt;
      if (lastPausedAt != null &&
          DateTime.now().difference(lastPausedAt) >=
              const Duration(seconds: 5)) {
        _appOpenAdManager.showAdIfAvailable();
      }
    }
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final lightTheme = widget.controller.resolveLight(dynamicScheme: _dynLight);
    final darkTheme = widget.controller.resolveDark(dynamicScheme: _dynDark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleepy Audio App',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: widget.controller.themeMode,
      home: widget.homeOverride ?? AudioHomePage(controller: widget.controller),
      builder: (context, child) {
        return _AppScaffold(controller: widget.controller, child: child);
      },
    );
  }
}

class _AppScaffold extends StatelessWidget {
  final Widget? child;
  final ThemeController controller;
  const _AppScaffold({required this.child, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) {
        if (settings.name == '/theme-settings') {
          return MaterialPageRoute(
            builder: (_) => ThemeSettingsScreen(controller: controller),
          );
        }
        return MaterialPageRoute(
            builder: (_) => child ?? const SizedBox.shrink());
      },
    );
  }
}
