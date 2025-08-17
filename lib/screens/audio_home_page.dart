import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/screens/explain_screen.dart';
import 'package:flutter_sleepy/services/audio_service.dart';
import 'package:flutter_sleepy/utils/battery_optimization.dart';
import 'package:flutter_sleepy/utils/duration_formatter.dart';
import 'package:flutter_sleepy/widgets/audio_controls.dart';
import 'package:flutter_sleepy/widgets/timer_button.dart';
import 'package:flutter_sleepy/widgets/custom_timer_dialog.dart';
import 'package:just_audio/just_audio.dart';

/// The main home page for the Sleepy Audio app.  It exposes controls
/// for selecting the audio track, adjusting playback and timer
/// settings, and navigating to an information screen.  The design
/// follows a dark theme consistent with the rest of the application.
class AudioHomePage extends StatefulWidget {
  const AudioHomePage({super.key});

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

  @override
  void dispose() {
    _audioService.dispose();
    FlutterBackgroundService().invoke('stopService');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Subtle premium gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0B141A),
                  Color(0xFF0F1E22),
                  Color(0xFF102529),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _glass(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: _buildTrackInfo(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _glass(
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _buildTrackSelector(),
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
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Sleepy Audio'),
    );
  }

  Widget _buildTrackInfo() {
    return StreamBuilder<SequenceState?>(
      stream: _audioService.player.sequenceStateStream,
      builder: (context, _) {
        return Text(
          'Now Playing: ${TracksData.tracks[_selectedIndex].title}',
          style: Theme.of(context).textTheme.titleLarge,
        );
      },
    );
  }

  Widget _buildTrackSelector() {
    return DropdownButton<int>(
      value: _selectedIndex,
      dropdownColor: Colors.blueGrey[800],
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
      underline: Container(
        height: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
      items: _buildTrackItems(),
      onChanged: _onTrackChanged,
    );
  }

  List<DropdownMenuItem<int>> _buildTrackItems() {
    return TracksData.tracks.asMap().entries.map((entry) {
      return DropdownMenuItem<int>(
        value: entry.key,
        child: Text(entry.value.title),
      );
    }).toList();
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
              : Colors.white70,
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
        child: const Text('커스텀'),
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
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: const Text('취소', style: TextStyle(color: Colors.white)),
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
      {'label': '10초', 'duration': const Duration(seconds: 10)},
      {'label': '1분', 'duration': const Duration(minutes: 1)},
      {'label': '5분', 'duration': const Duration(minutes: 5)},
      {'label': '10분', 'duration': const Duration(minutes: 10)},
      {'label': '15분', 'duration': const Duration(minutes: 15)},
      {'label': '30분', 'duration': const Duration(minutes: 30)},
      {'label': '1시간', 'duration': const Duration(hours: 1)},
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
    return ElevatedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ExplainScreen()),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueGrey[800],
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      ),
      child: Text(
        'How It Works',
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}