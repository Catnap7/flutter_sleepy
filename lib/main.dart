import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sleepy/screens/audio_home_page.dart';
import 'package:flutter_sleepy/screens/theme_settings_screen.dart';
import 'package:flutter_sleepy/services/background_service_stub.dart'
    if (dart.library.io) 'package:flutter_sleepy/services/background_service.dart';
import 'package:flutter_sleepy/services/metrics_service.dart';

import 'package:flutter_sleepy/theme/dynamic_color_helper.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';

typedef StartupTask = ({String label, Future<void> Function() run});

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = ThemeController();
  runApp(MyApp(controller: controller));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeAfterFirstFrame(controller));
  });
}

Future<void> _initializeAfterFirstFrame(ThemeController controller) {
  final tasks = <StartupTask>[
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS))
      (label: 'Background service', run: initializeService),
    (label: 'Theme preferences', run: controller.load),
    (label: 'Local metrics', run: MetricsService.instance.trackAppOpen),
  ];
  return runBestEffortStartupTasks(tasks);
}

@visibleForTesting
Future<void> runBestEffortStartupTasks(
  Iterable<StartupTask> tasks, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  await Future.wait(
    tasks.map(
      (task) async {
        try {
          await Future<void>.sync(task.run).timeout(timeout);
        } catch (error) {
          debugPrint('${task.label} initialization skipped: $error');
        }
      },
    ),
  );
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

class _MyAppState extends State<MyApp> {
  ColorScheme? _dynLight;
  ColorScheme? _dynDark;

  @override
  void initState() {
    super.initState();
    // Fetch dynamic color schemes (Android 12+)
    fetchDynamicSchemes().then((schemes) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dynLight = schemes.$1;
        _dynDark = schemes.$2;
      });
    }).catchError((Object error) {
      debugPrint('Dynamic colors unavailable: $error');
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
