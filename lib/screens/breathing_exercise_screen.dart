import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

enum _BreathingSound {
  none,
  rainy,
  campFire,
  waves,
}

extension _BreathingSoundX on _BreathingSound {
  String get label {
    switch (this) {
      case _BreathingSound.none:
        return 'None';
      case _BreathingSound.rainy:
        return 'Rainy';
      case _BreathingSound.campFire:
        return 'Camp Fire';
      case _BreathingSound.waves:
        return 'Waves';
    }
  }

  String? get assetPath {
    switch (this) {
      case _BreathingSound.none:
        return null;
      case _BreathingSound.rainy:
        return 'assets/audio/rain_noise.wav';
      case _BreathingSound.campFire:
        return 'assets/audio/fire_noise.wav';
      case _BreathingSound.waves:
        return 'assets/audio/wave.mp3';
    }
  }
}

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final AudioPlayer _ambientPlayer;
  late final FlutterTts _tts;

  String _instruction = 'Ready to Start?';
  bool _isRunning = false;
  bool _ttsEnabled = false;
  _BreathingSound _selectedSound = _BreathingSound.none;
  double _ambientVolume = 0.35;

  final int _inhaleTime = 4;
  final int _holdTime = 7;
  final int _exhaleTime = 8;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _animation = Tween<double>(begin: 80.0, end: 220.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _ambientPlayer = AudioPlayer();
    _tts = FlutterTts();
    unawaited(_configureTts());
  }

  @override
  void dispose() {
    _isRunning = false;
    _controller.stop(canceled: true);
    unawaited(_ambientPlayer.stop());
    unawaited(_tts.stop());
    _ambientPlayer.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(false);
    } catch (_) {
      // Keep breathing UX functional even when TTS is unavailable.
    }
  }

  Future<void> _toggleExercise() async {
    if (_isRunning) {
      await _stopExercise(resetVisuals: true);
      return;
    }

    setState(() => _isRunning = true);
    await _restartAmbientSound();
    unawaited(_runBreathingCycle());
  }

  Future<void> _stopExercise({required bool resetVisuals}) async {
    _isRunning = false;
    _controller.stop(canceled: true);
    await _ambientPlayer.stop();
    await _tts.stop();

    if (!mounted || !resetVisuals) {
      return;
    }

    setState(() {
      _controller.value = 0.0;
      _instruction = 'Ready to Start?';
    });
  }

  Future<void> _restartAmbientSound() async {
    await _ambientPlayer.stop();
    final soundPath = _selectedSound.assetPath;
    if (!_isRunning || soundPath == null) {
      return;
    }

    try {
      await _ambientPlayer.setAsset(soundPath);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.setVolume(_ambientVolume);
      await _ambientPlayer.play();
    } catch (_) {
      // Keep breathing UX functional even when audio assets fail.
    }
  }

  Future<void> _speakCue(String text) async {
    if (!_ttsEnabled || !_isRunning) {
      return;
    }

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {
      // Keep breathing UX functional even when TTS is unavailable.
    }
  }

  Future<bool> _waitWhileRunning(Duration duration) async {
    var elapsed = Duration.zero;
    const tick = Duration(milliseconds: 100);

    while (elapsed < duration) {
      if (!_isRunning || !mounted) {
        return false;
      }
      final remaining = duration - elapsed;
      final wait = remaining < tick ? remaining : tick;
      await Future.delayed(wait);
      elapsed += wait;
    }

    return _isRunning && mounted;
  }

  Future<void> _runBreathingCycle() async {
    while (_isRunning && mounted) {
      if (!_isRunning) {
        break;
      }
      setState(() {
        _instruction = 'Breathe In...';
        _controller.duration = Duration(seconds: _inhaleTime);
      });
      unawaited(_speakCue('Breathe in'));
      try {
        await _controller.forward(from: 0.0).orCancel;
      } on TickerCanceled {
        break;
      }

      if (!_isRunning) {
        break;
      }
      setState(() => _instruction = 'Hold');
      unawaited(_speakCue('Hold'));
      final shouldContinue = await _waitWhileRunning(
        Duration(seconds: _holdTime),
      );
      if (!shouldContinue) {
        break;
      }

      if (!_isRunning) {
        break;
      }
      setState(() {
        _instruction = 'Breathe Out...';
        _controller.duration = Duration(seconds: _exhaleTime);
      });
      unawaited(_speakCue('Breathe out'));
      try {
        await _controller.reverse(from: 1.0).orCancel;
      } on TickerCanceled {
        break;
      }
    }
  }

  Future<void> _onSoundChanged(_BreathingSound sound) async {
    setState(() => _selectedSound = sound);
    if (_isRunning) {
      await _restartAmbientSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('4-7-8 Breathing'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.primary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Container(
                        width: _animation.value,
                        height: _animation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  Text(
                    _instruction,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _toggleExercise,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      backgroundColor: _isRunning
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.primary,
                      foregroundColor: _isRunning
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      _isRunning ? 'Stop' : 'Start',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            theme.colorScheme.outline.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Breathing Guidance',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _BreathingSound.values
                              .map(
                                (sound) => ChoiceChip(
                                  label: Text(sound.label),
                                  selected: sound == _selectedSound,
                                  onSelected: (_) => _onSoundChanged(sound),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sound Volume',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _ambientVolume,
                          min: 0,
                          max: 1,
                          onChanged: (value) {
                            setState(() => _ambientVolume = value);
                            _ambientPlayer.setVolume(value);
                          },
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Voice coach (TTS cues)'),
                          subtitle: const Text(
                            'Short guidance only at inhale/hold/exhale transitions',
                          ),
                          value: _ttsEnabled,
                          onChanged: (enabled) async {
                            setState(() => _ttsEnabled = enabled);
                            if (!enabled) {
                              await _tts.stop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
