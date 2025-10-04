import 'dart:ui';
import 'package:flutter/material.dart';
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

class _TimerPreset {
  const _TimerPreset(this.label, this.duration);

  final String label;
  final Duration duration;
}

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

  static const List<_TimerPreset> _timerPresets = [
    _TimerPreset('10s', Duration(seconds: 10)),
    _TimerPreset('1m', Duration(minutes: 1)),
    _TimerPreset('5m', Duration(minutes: 5)),
    _TimerPreset('10m', Duration(minutes: 10)),
    _TimerPreset('15m', Duration(minutes: 15)),
    _TimerPreset('30m', Duration(minutes: 30)),
    _TimerPreset('45m', Duration(minutes: 45)),
    _TimerPreset('1h', Duration(hours: 1)),
    _TimerPreset('2h', Duration(hours: 2)),
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _audioService = AudioService();
    await _runServiceStep(
      () => BatteryOptimizationHandler.ignoreBatteryOptimization(),
      'Battery optimization request',
    );
    await _runServiceStep(
      _initializeAudio,
      'Audio initialize',
    );
    await _runServiceStep(
      _startBackgroundService,
      'Background service start',
    );
  }

  Future<void> _runServiceStep(
    Future<void> Function() action,
    String debugLabel,
  ) async {
    try {
      await action();
    } catch (error) {
      debugPrint('$debugLabel skipped: $error');
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

  Future<void> _selectTrack(int index) async {
    if (index < 0 || index >= TracksData.tracks.length) {
      return;
    }
    if (index == _selectedIndex) {
      return;
    }

    setState(() => _selectedIndex = index);
    await _setTrack(index);
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
    if (index != null) {
      await _selectTrack(index);
    }
  }

  Future<void> _onSoundKeyChanged(String key) async {
    final index = _resolveTrackIndex(key);
    await _selectTrack(index);
  }

  int _resolveTrackIndex(String key) {
    final normalizedKey = key.trim().toLowerCase();
    final index = TracksData.tracks.indexWhere(
      (track) => track.title.toLowerCase() == normalizedKey,
    );
    return index >= 0 ? index : 0;
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
      actions: [
        IconButton(
          tooltip: 'Theme',
          icon: const Icon(Icons.color_lens_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ThemeSettingsScreen(controller: widget.controller)),
          ),
        ),
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
            _startTimer(customDuration);
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
          onPressed: _cancelTimer,
          style: ElevatedButton.styleFrom(
            padding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: const Text('Cancel'),
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
    return _timerPresets
        .map(
          (preset) => TimerButton(
            label: preset.label,
            duration: preset.duration,
            onPressed: () => _startTimer(preset.duration),
          ),
        )
        .toList();
  }

  void _startTimer(Duration duration) {
    _audioService.startTimer(duration);
    _sendNowPlayingUpdate();
  }

  void _cancelTimer() {
    _audioService.cancelTimer();
    _sendNowPlayingUpdate();
  }

  Widget _buildHowItWorksButton() {
    return ThemedActionButton(
      label: 'How It Works',
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