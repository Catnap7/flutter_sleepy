import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sleepy/screens/audio_home_page.dart';
import 'package:flutter_sleepy/screens/theme_settings_screen.dart';
import 'package:flutter_sleepy/services/background_service_stub.dart'
    if (dart.library.io) 'package:flutter_sleepy/services/background_service.dart';

import 'package:flutter_sleepy/theme/dynamic_color_helper.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      await initializeService();
    }
  } catch (e) {
    debugPrint('Failed to initialize background service: $e');
  }
  final controller = ThemeController();
  await controller.load();
  runApp(MyApp(controller: controller));
}

class MyApp extends StatefulWidget {
  final ThemeController controller;
  const MyApp({super.key, required this.controller});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ColorScheme? _dynLight;
  ColorScheme? _dynDark;

  @override
  void initState() {
    super.initState();
    // Fetch dynamic color schemes (Android 12+)
    fetchDynamicSchemes().then((schemes) {
      setState(() {
        _dynLight = schemes.$1;
        _dynDark = schemes.$2;
      });
    });
    widget.controller.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final lightTheme = widget.controller.resolveLight(dynamicScheme: _dynLight);
    final darkTheme = widget.controller.resolveDark(dynamicScheme: _dynDark);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleepy Audio App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: widget.controller.themeMode,
      home: AudioHomePage(controller: widget.controller),
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
        return MaterialPageRoute(builder: (_) => child ?? const SizedBox.shrink());
      },
    );
  }
}
