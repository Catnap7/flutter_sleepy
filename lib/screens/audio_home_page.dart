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
  Duration _remainingTime = const Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _audioService = AudioService();
    await BatteryOptimizationHandler.ignoreBatteryOptimization();
    await _initializeAudio();
    await _startBackgroundService();
  }

  Future<void> _initializeAudio() async {
    await _audioService.initialize();
    await _setTrack(_selectedIndex);
    _setupTimerListener();
  }

  void _setupTimerListener() {
    _audioService.timerStream.listen(_updateRemainingTime);
  }

  void _updateRemainingTime(Duration duration) {
    setState(() => _remainingTime = duration);
  }

  Future<void> _setTrack(int index) async {
    await _audioService.setTrack(TracksData.tracks[index]);
  }

  Future<void> _startBackgroundService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    service.invoke('setAsForeground');
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
              _buildHowItWorksButton(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Sleepy Audio'),
      backgroundColor: Colors.blueGrey[900],
      elevation: 0,
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
      style: const TextStyle(color: Colors.tealAccent),
      underline: Container(
        height: 2,
        color: Colors.tealAccent,
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
    return Text(
      _remainingTime > Duration.zero
          ? 'Remaining Time: ${DurationFormatter.format(_remainingTime)}'
          : 'No Timer Set',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: _remainingTime > Duration.zero ? Colors.tealAccent : Colors.white70,
      ),
    );
  }

  Widget _buildTimerButtons() {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: _buildTimerButtonsList(),
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
        onPressed: () => _audioService.startTimer(timer['duration'] as Duration),
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
      child: const Text(
        'How It Works',
        style: TextStyle(color: Colors.tealAccent),
      ),
    );
  }
}