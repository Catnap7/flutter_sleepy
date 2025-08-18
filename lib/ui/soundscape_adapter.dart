import 'package:flutter/material.dart';
import '../utils/soundscapes.dart';

/// Global route observer used to detect when a page becomes hidden/visible.
class SoundscapeRouteObserver {
  static final RouteObserver<ModalRoute<void>> instance = RouteObserver<ModalRoute<void>>();
}

/// Map our app's sound key to the Soundscape enum.
/// Accept both "camp fire" and "campfire".
Soundscape mapSoundKeyToScape(String key) {
  final k = key.trim().toLowerCase();
  if (k.contains('wave')) return Soundscape.waves;
  if (k.replaceAll(' ', '') == 'campfire') return Soundscape.campfire;
  if (k.contains('rainy')) return Soundscape.rainy;
  return Soundscape.pinknoise; // default
}

/// Lifecycle gate to pause animations when app is not active.
class LifecycleGate extends StatefulWidget {
  const LifecycleGate({super.key, required this.child});
  final Widget child;

  @override
  State<LifecycleGate> createState() => _LifecycleGateState();
}

class _LifecycleGateState extends State<LifecycleGate> with WidgetsBindingObserver {
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _active = state == AppLifecycleState.resumed);
  }

  @override
  Widget build(BuildContext context) => TickerMode(enabled: _active, child: widget.child);
}

/// Drop-in container: renders the reactive FX background under your content.
class SoundReactiveBackground extends StatelessWidget {
  const SoundReactiveBackground({
    super.key,
    required this.currentSoundKey,
    this.intensity = 1.0,          // 0.5 ~ 1.5 recommended
    required this.child,
  });

  final String currentSoundKey;
  final double intensity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scape = mapSoundKeyToScape(currentSoundKey);
    return LifecycleGate(
      child: Stack(
        children: [
          Positioned.fill(child: SoundscapeBackground(mode: scape, intensity: intensity)),
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: child,
            ),
          ),
        ],
      ),
    );
  }
}
