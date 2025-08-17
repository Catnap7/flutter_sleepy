import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sleepy/screens/audio_home_page.dart';
import 'package:flutter_sleepy/services/background_service_stub.dart'
    if (dart.library.io) 'package:flutter_sleepy/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      await initializeService();
    }
  } catch (e) {
    debugPrint('Failed to initialize background service: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = const ColorScheme.dark(
      primary: Colors.tealAccent,
      secondary: Colors.teal,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleepy Audio App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.blueGrey[900],
        colorScheme: baseScheme,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w700),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.tealAccent,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: Colors.tealAccent),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.06),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.blueGrey[850],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titleTextStyle: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: baseScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.0),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: baseScheme.primary,
            side: BorderSide(color: baseScheme.primary.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.tealAccent,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: baseScheme.primary,
          inactiveTrackColor: baseScheme.primary.withOpacity(0.25),
          thumbColor: baseScheme.primary,
          overlayColor: baseScheme.primary.withOpacity(0.15),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
        ),
      ),
      home: const AudioHomePage(),
    );
  }
}

