import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_sleepy/screens/audio_home_page.dart';
import 'package:flutter_sleepy/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sleepy Audio App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.blueGrey[900],
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge:
              TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.tealAccent,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.tealAccent,
          inactiveTrackColor: Colors.tealAccent.withOpacity(0.3),
          thumbColor: Colors.tealAccent,
          overlayColor: Colors.tealAccent.withOpacity(0.2),
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
        ),
      ),
      home: AudioHomePage(),
    );
  }
}

