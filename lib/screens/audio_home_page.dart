import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sleepy/l10n/l10n_ext.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/screens/explain_screen.dart';
import 'package:flutter_sleepy/services/audio_service.dart';
import 'package:flutter_sleepy/theme/app_theme.dart';
import 'package:flutter_sleepy/ui/themed_action_button.dart';
import 'package:flutter_sleepy/utils/battery_optimization.dart';
import 'package:flutter_sleepy/utils/duration_formatter.dart';
import 'package:flutter_sleepy/widgets/audio_controls.dart';
import 'package:flutter_sleepy/widgets/timer_button.dart';
import 'package:flutter_sleepy/widgets/custom_timer_dialog.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sleepy/ui/soundscape_adapter.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';
import 'package:flutter_sleepy/ui/sound_selector.dart';

/// The main home page for the Sleepy Audio app.  It exposes controls
/// for selecting the audio track, adjusting playback and timer
/// settings, and navigating to an information screen.  The design
/// follows a dark theme consistent with the rest of the application.
class AudioHomePage extends StatefulWidget {
  final ThemeController controller;
  const AudioHomePage({super.key, required this.controller});

  @override
  State<AudioHomePage> createState() => _AudioHomePageState();
}

class _AudioHomePageState extends State<AudioHomePage> {
  late final AudioService _audioService;
  int _selectedIndex = 0;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _audioService = AudioService();
    try {
      await BatteryOptimizationHandler.ignoreBatteryOptimization();
    } catch (e) {
      debugPrint('Battery optimization request skipped: $e');
    }
    try {
      await _initializeAudio();
    } catch (e) {
      debugPrint('Audio initialize skipped: $e');
    }
    try {
      await _startBackgroundService();
    } catch (e) {
      debugPrint('Background service start skipped: $e');
    }
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    await _setTrack(_selectedIndex);
    _setupTimerListener();
    _setupPlayerStateListener();
  }

  void _setupTimerListener() {
    _audioService.timerStream.listen(_updateRemainingTime);
  }

  void _setupPlayerStateListener() {
    _audioService.player.playerStateStream.listen((_) {
      _sendNowPlayingUpdate();
    });
  }

  void _updateRemainingTime(Duration duration) {
    setState(() => _remainingTime = duration);
    _sendNowPlayingUpdate();
  }

  Future<void> _setTrack(int index) async {
    try {
      await _audioService.setTrack(TracksData.tracks[index]);
      _sendNowPlayingUpdate();
    } catch (e) {
      debugPrint('Set track failed: $e');
    }
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service.invoke('setAsForeground');
  }

  void _sendNowPlayingUpdate() {
    final service = FlutterBackgroundService();
    final trackTitle = TracksData.tracks[_selectedIndex].title;
    final isPlaying = _audioService.player.playing;

    String title = 'Sleepy — $trackTitle';
    String content;

    if (isPlaying && _remainingTime > Duration.zero) {
      content = 'Playing • ${DurationFormatter.format(_remainingTime)} left';
    } else if (isPlaying) {
      content = 'Playing';
    } else if (!isPlaying && _remainingTime > Duration.zero) {
      content = 'Paused • ${DurationFormatter.format(_remainingTime)} left';
    } else {
      content = 'Ready';
    }

    service.invoke('updateNotification', {
      'title': title,
      'content': content,
    });
  }

  Future<void> _onTrackChanged(int? index) async {
    if (index != null && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      await _setTrack(index);
    }
  }

  Future<void> _onSoundKeyChanged(String key) async {
    final k = key.trim().toLowerCase();
    int index;
    if (k.contains('wave')) {
      index = TracksData.tracks.indexWhere((t) => t.title.toLowerCase().contains('waves'));
    } else if (k.replaceAll(' ', '') == 'campfire') {
      index = TracksData.tracks.indexWhere((t) => t.title.toLowerCase().contains('camp fire'));
    } else if (k.contains('rainy')) {
      index = TracksData.tracks.indexWhere((t) => t.title.toLowerCase().contains('rainy'));
    } else {
      index = TracksData.tracks.indexWhere((t) => t.title.toLowerCase().contains('pink noise'));
    }
    if (index < 0) index = 0;
    if (index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      await _setTrack(index);
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    FlutterBackgroundService().invoke('stopService');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final baseTheme = Theme.of(context);
    final currentTitle = TracksData.tracks[_selectedIndex].title; // e.g. "Rainy"

// Map the current sound to an accent and tint the local theme
    final accent = AppSoundAccent.fromTitle(currentTitle);
    final tinted = AppThemeAccentAPI.withSoundAccent(baseTheme, accent,
        recolorSecondary: false // set true if you want secondary/tertiary to shift too
    );

    return Theme(
      data: tinted,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(),
        body: SoundReactiveBackground(
          currentSoundKey: TracksData.tracks[_selectedIndex].title,
          intensity: widget.controller.bgIntensity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  _glass(
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SoundSelectorCard(
                        value: TracksData.tracks[_selectedIndex].title.toLowerCase(),
                        onChanged: _onSoundKeyChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AudioControls(
                    _audioService.player,
                    onPlayPauseChanged: (isPlaying) => _sendNowPlayingUpdate(),
                  ),
                  const SizedBox(height: 20),
                  _glass(
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildTimerSection(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: _buildHowItWorksButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      actions: [/*
        IconButton(
          tooltip: 'Theme',
          icon: const Icon(Icons.color_lens_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ThemeSettingsScreen(controller: controller)),
          ),
        ),*/
      ],
      title: const Text('Sleepy Audio'),
    );
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        _buildTimerDisplay(),
        const SizedBox(height: 10),
        _buildTimerButtons(),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    final label = _remainingTime > Duration.zero
        ? 'Remaining Time: ${DurationFormatter.format(_remainingTime)}'
        : 'No Timer Set';
    return Semantics(
      label: _remainingTime > Duration.zero
          ? 'Timer running, ${DurationFormatter.format(_remainingTime)} remaining'
          : 'No timer set',
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _remainingTime > Duration.zero
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Builds the row of timer control buttons.  In addition to the
  /// pre-defined timer presets, a custom timer and cancel button are
  /// included.  The cancel button only appears when a timer is
  /// currently running.
  Widget _buildTimerButtons() {
    final buttons = <Widget>[
      ..._buildTimerButtonsList(),
      // Button to trigger custom timer dialog
      ElevatedButton(
        onPressed: () async {
          final customDuration = await showCustomTimerDialog(
            context: context,
            minMinutes: 1,
            maxMinutes: 180,
            initialMinutes: _remainingTime.inMinutes > 0
                ? _remainingTime.inMinutes
                : 30,
          );
          if (customDuration != null) {
            _audioService.startTimer(customDuration);
            _sendNowPlayingUpdate();
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Text('Custom'),
      ),
    ];

    // If a timer is active, provide a cancel button
    if (_remainingTime > Duration.zero) {
      buttons.add(
        ElevatedButton(
          onPressed: () {
            _audioService.cancelTimer();
            _sendNowPlayingUpdate();
          },
          style: ElevatedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: const Text('취소'),
        ),
      );
    }

    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: buttons,
    );
  }

  List<Widget> _buildTimerButtonsList() {
    final timerDurations = [
      {'label': '10s', 'duration': const Duration(seconds: 10)},
      {'label': '1m', 'duration': const Duration(minutes: 1)},
      {'label': '5m', 'duration': const Duration(minutes: 5)},
      {'label': '10m', 'duration': const Duration(minutes: 10)},
      {'label': '15m', 'duration': const Duration(minutes: 15)},
      {'label': '30m', 'duration': const Duration(minutes: 30)},
      {'label': '45m', 'duration': const Duration(minutes: 45)},
      {'label': '1h', 'duration': const Duration(hours: 1)},
      {'label': '2h', 'duration': const Duration(hours: 2)},
    ];

    return timerDurations.map((timer) {
      return TimerButton(
        label: timer['label'] as String,
        duration: timer['duration'] as Duration,
        onPressed: () {
          _audioService.startTimer(timer['duration'] as Duration);
          _sendNowPlayingUpdate();
        },
      );
    }).toList();
  }

  Widget _buildHowItWorksButton() {
    return ThemedActionButton(
      label: context.l10n.howItWorks,
      icon: Icons.auto_awesome_rounded,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ExplainScreenV2()),
      ),
    );
  }

  Widget _glass(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(20)),
          ),
          child: child,
        ),
      ),
    );
  }
}
