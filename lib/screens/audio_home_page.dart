import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/screens/explain_screen.dart';
import 'package:flutter_sleepy/services/audio_service.dart';
import 'package:flutter_sleepy/utils/battery_optimization.dart';
import 'package:flutter_sleepy/utils/duration_formatter.dart';
import 'package:flutter_sleepy/widgets/audio_controls.dart';
import 'package:flutter_sleepy/widgets/timer_button.dart';
import 'package:just_audio/just_audio.dart';

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
    _audioService = AudioService();
    BatteryOptimizationHandler.ignoreBatteryOptimization();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    await _setTrack(_selectedIndex);
    _setupTimerListener();
    _startBackgroundService();
  }

  void _setupTimerListener() {
    _audioService.timerStream.listen((duration) {
      setState(() => _remainingTime = duration);
    });
  }

  Future<void> _setTrack(int index) async {
    await _audioService.setTrack(TracksData.tracks[index]);
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      service.startService();
    }
    service.invoke('setAsForeground');
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
      appBar: AppBar(
        title: const Text('Sleepy Audio'),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildTrackInfo(),
              const SizedBox(height: 30),
              _buildTrackSelector(),
              const SizedBox(height: 30),
              AudioControls(_audioService.player),
              const SizedBox(height: 30),
              _buildTimerSection(),
              const SizedBox(height: 30),
              // move to explain_screen
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ExplainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text(
                  'How It Works',
                  style: TextStyle(color: Colors.tealAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackInfo() {
    return StreamBuilder<SequenceState?>(
      stream: _audioService.player.sequenceStateStream,
      builder: (context, snapshot) {
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
      style: const TextStyle(color: Colors.tealAccent),
      underline: Container(
        height: 2,
        color: Colors.tealAccent,
      ),
      items: TracksData.tracks.asMap().entries.map((entry) {
        return DropdownMenuItem<int>(
          value: entry.key,
          child: Text(entry.value.title),
        );
      }).toList(),
      onChanged: _onTrackChanged,
    );
  }

  Future<void> _onTrackChanged(int? index) async {
    if (index != null && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
      await _setTrack(index);
      _audioService.player.play();
    }
  }

  Widget _buildTimerSection() {
    return Column(
      children: [
        Text(
          _remainingTime > Duration.zero
              ? 'Remaining Time: ${DurationFormatter.format(_remainingTime)}'
              : 'No Timer Set',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _remainingTime > Duration.zero
                ? Colors.tealAccent
                : Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        _buildTimerButtons(),
        if (_remainingTime > Duration.zero) _buildCancelButton(),
      ],
    );
  }

  Widget _buildTimerButtons() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: [
        TimerButton(
          label: '10초',
          duration: const Duration(seconds: 10),
          onPressed: () =>
              _audioService.startTimer(const Duration(seconds: 10)),
        ),
        TimerButton(
          label: '1분',
          duration: const Duration(minutes: 1),
          onPressed: () => _audioService.startTimer(const Duration(minutes: 1)),
        ),
        TimerButton(
          label: '5분',
          duration: const Duration(minutes: 5),
          onPressed: () => _audioService.startTimer(const Duration(minutes: 5)),
        ),
        TimerButton(
          label: '10분',
          duration: const Duration(minutes: 10),
          onPressed: () =>
              _audioService.startTimer(const Duration(minutes: 10)),
        ),
        TimerButton(
          label: '15분',
          duration: const Duration(minutes: 15),
          onPressed: () =>
              _audioService.startTimer(const Duration(minutes: 15)),
        ),
        TimerButton(
          label: '30분',
          duration: const Duration(minutes: 30),
          onPressed: () =>
              _audioService.startTimer(const Duration(minutes: 30)),
        ),
        TimerButton(
          label: '1시간',
          duration: const Duration(hours: 1),
          onPressed: () => _audioService.startTimer(const Duration(hours: 1)),
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ElevatedButton(
        onPressed: _audioService.cancelTimer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
        ),
        child: const Text('타이머 취소'),
      ),
    );
  }
}
