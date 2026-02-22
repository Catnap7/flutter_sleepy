import 'dart:ui';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_sleepy/constants/admob_constants.dart';
import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/screens/breathing_exercise_screen.dart';
import 'package:flutter_sleepy/screens/explain_screen.dart';
import 'package:flutter_sleepy/screens/theme_settings_screen.dart';
import 'package:flutter_sleepy/services/audio_service.dart';
import 'package:flutter_sleepy/services/metrics_service.dart';
import 'package:flutter_sleepy/theme/app_theme.dart';
import 'package:flutter_sleepy/ui/themed_action_button.dart';
import 'package:flutter_sleepy/utils/battery_optimization.dart';
import 'package:flutter_sleepy/utils/duration_formatter.dart';
import 'package:flutter_sleepy/widgets/audio_controls.dart';
import 'package:flutter_sleepy/widgets/timer_button.dart';
import 'package:flutter_sleepy/widgets/custom_timer_dialog.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sleepy/ui/soundscape_adapter.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';
import 'package:flutter_sleepy/ui/sound_selector.dart';

class _TimerPreset {
  const _TimerPreset(this.label, this.duration);

  final String label;
  final Duration duration;
}

enum _BatteryPromptAction {
  allow,
  notNow,
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

class _AudioHomePageState extends State<AudioHomePage>
    with WidgetsBindingObserver {
  late final AudioService _audioService;
  int _selectedIndex = 0;
  Duration _remainingTime = Duration.zero;
  StreamSubscription<Duration>? _timerSub;
  StreamSubscription<PlayerState>? _playerSub;
  Timer? _stopServiceDebounce;
  int _lastNotificationBucket = -1;
  bool _batteryPromptInProgress = false;
  bool _fadeOutEnabled = true;
  bool _wasPlaying = false;
  Duration _lastRemainingTime = Duration.zero;
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  static const List<_TimerPreset> _timerPresets = [
    _TimerPreset('15m', Duration(minutes: 15)),
    _TimerPreset('30m', Duration(minutes: 30)),
    _TimerPreset('45m', Duration(minutes: 45)),
    _TimerPreset('1h', Duration(hours: 1)),
    _TimerPreset('1h 30m', Duration(minutes: 90)),
    _TimerPreset('2h', Duration(hours: 2)),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _loadNativeAd();
  }

  Future<void> _initializeServices() async {
    _audioService = AudioService();
    await _runServiceStep(
      _initializeAudio,
      'Audio initialize',
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
    final didLoadInitialTrack = await _setTrack(_selectedIndex);
    if (!didLoadInitialTrack) {
      await _loadFirstPlayableTrack();
    }
    _setupTimerListener();
    _setupPlayerStateListener();
  }

  void _setupTimerListener() {
    _timerSub?.cancel();
    _timerSub = _audioService.timerStream.listen(_updateRemainingTime);
  }

  void _setupPlayerStateListener() {
    _playerSub?.cancel();
    _playerSub = _audioService.player.playerStateStream.listen((state) {
      _handlePlayerState(state);
    });
  }

  void _updateRemainingTime(Duration duration) {
    if (_lastRemainingTime > Duration.zero && duration == Duration.zero) {
      unawaited(MetricsService.instance.track('timer_completed'));
    }
    _lastRemainingTime = duration;
    setState(() => _remainingTime = duration);
    _sendNowPlayingUpdate();
  }

  void _handlePlayerState(PlayerState state) {
    final isPlaying = state.playing &&
        state.processingState != ProcessingState.loading &&
        state.processingState != ProcessingState.buffering;

    if (isPlaying) {
      if (!_wasPlaying) {
        unawaited(MetricsService.instance.track('playback_started'));
      }
      _wasPlaying = true;
      _stopServiceDebounce?.cancel();
      _ensureBackgroundServiceRunning();
      _sendNowPlayingUpdate(force: true);
      return;
    }

    _wasPlaying = false;
    // Stop the foreground service shortly after pausing to avoid notification flicker.
    _stopServiceDebounce?.cancel();
    _stopServiceDebounce = Timer(const Duration(milliseconds: 1500), () {
      _stopBackgroundService();
    });
  }

  Future<bool> _setTrack(int index) async {
    try {
      await _audioService.setTrack(TracksData.tracks[index]);
      _sendNowPlayingUpdate(force: true);
      return true;
    } catch (e) {
      debugPrint('Set track failed: $e');
      return false;
    }
  }

  Future<void> _selectTrack(int index) async {
    if (index < 0 || index >= TracksData.tracks.length) {
      return;
    }
    if (index == _selectedIndex) {
      return;
    }

    final previousIndex = _selectedIndex;
    setState(() => _selectedIndex = index);
    final didLoadTrack = await _setTrack(index);
    if (!didLoadTrack) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedIndex = previousIndex);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('선택한 사운드를 재생할 수 없어 이전 사운드로 복원했어요.'),
          ),
        );
      unawaited(MetricsService.instance.track(
        'sound_select_failed',
        properties: {
          'track_id': TracksData.tracks[index].id,
        },
      ));
      return;
    }

    unawaited(MetricsService.instance.track(
      'sound_selected',
      properties: {
        'track_id': TracksData.tracks[index].id,
      },
    ));
  }

  Future<void> _loadFirstPlayableTrack() async {
    for (var i = 0; i < TracksData.tracks.length; i++) {
      final didLoadTrack = await _setTrack(i);
      if (!didLoadTrack) {
        continue;
      }
      if (!mounted) {
        return;
      }
      if (_selectedIndex != i) {
        setState(() => _selectedIndex = i);
      }
      return;
    }
    debugPrint('No playable tracks found.');
  }

  Future<void> _ensureBackgroundServiceRunning() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      service.invoke('setAsForeground');
      return;
    }

    await service.startService();
    service.invoke('setAsForeground');
  }

  Future<void> _stopBackgroundService() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      return;
    }
    service.invoke('stopService');
  }

  Future<bool> _handlePlayRequest() async {
    await _maybeShowBatteryOptimizationEducation();
    return true;
  }

  Future<void> _maybeShowBatteryOptimizationEducation() async {
    if (!mounted || _batteryPromptInProgress) {
      return;
    }
    final shouldShow = await BatteryOptimizationHandler.shouldShowEducation();
    if (!shouldShow || !mounted) {
      return;
    }

    _batteryPromptInProgress = true;
    try {
      final action = await _showBatteryOptimizationSheet();
      await BatteryOptimizationHandler.markEducationShown();
      unawaited(
          MetricsService.instance.track('battery_optimization_prompt_shown'));
      if (action == _BatteryPromptAction.allow) {
        await BatteryOptimizationHandler.requestIgnoreBatteryOptimization();
        unawaited(
            MetricsService.instance.track('battery_optimization_allowed'));
      } else {
        unawaited(
            MetricsService.instance.track('battery_optimization_skipped'));
      }
    } finally {
      _batteryPromptInProgress = false;
    }
  }

  Future<_BatteryPromptAction?> _showBatteryOptimizationSheet() {
    return showModalBottomSheet<_BatteryPromptAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Keep playback stable in the background',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'On some Android devices, battery optimization may stop sounds when the screen turns off. '
                'You can allow Sleepy to ignore this optimization for smoother overnight playback.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, _BatteryPromptAction.notNow),
                      child: const Text('Not now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: () =>
                          Navigator.pop(context, _BatteryPromptAction.allow),
                      child: const Text('Allow'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  void _sendNowPlayingUpdate({bool force = false}) {
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

    // Avoid updating the foreground notification every second.
    // Bucket by 30s when a timer is running; always update on force.
    final bucket =
        _remainingTime > Duration.zero ? (_remainingTime.inSeconds ~/ 30) : 0;
    if (!force && bucket == _lastNotificationBucket) {
      return;
    }
    _lastNotificationBucket = bucket;

    service.invoke('updateNotification', {
      'title': title,
      'content': content,
    });
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

  bool get _shouldShowNativeAd =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void _loadNativeAd() {
    if (!_shouldShowNativeAd) {
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: androidNativeAdUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _nativeAd = ad as NativeAd;
            _isNativeAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('NativeAd failed to load: $error');
          if (!mounted) {
            return;
          }
          setState(() {
            _nativeAd = null;
            _isNativeAdLoaded = false;
          });
        },
      ),
    )..load();
  }

  Widget _buildNativeAdSection() {
    if (!_shouldShowNativeAd || !_isNativeAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return _glass(
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 320,
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    _audioService.dispose();
    _timerSub?.cancel();
    _playerSub?.cancel();
    _stopServiceDebounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    FlutterBackgroundService().invoke('stopService');
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(MetricsService.instance.track('entered_background'));
      if (_audioService.player.playing) {
        unawaited(MetricsService.instance.track('background_with_playback'));
      }
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(MetricsService.instance.track('returned_foreground'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final currentTitle =
        TracksData.tracks[_selectedIndex].title; // e.g. "Rainy"

// Map the current sound to an accent and tint the local theme
    final accent = AppSoundAccent.fromTitle(currentTitle);
    final tinted = AppThemeAccentAPI.withSoundAccent(baseTheme, accent,
        recolorSecondary:
            false // set true if you want secondary/tertiary to shift too
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
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _glass(
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SoundSelectorCard(
                      value:
                          TracksData.tracks[_selectedIndex].title.toLowerCase(),
                      onChanged: _onSoundKeyChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AudioControls(
                  _audioService.player,
                  volume: _audioService.volume,
                  volumeStream: _audioService.volumeStream,
                  onVolumeChanged: _audioService.setVolume,
                  onPlayRequested: _handlePlayRequest,
                  onPlayPauseChanged: (isPlaying) =>
                      _sendNowPlayingUpdate(force: true),
                ),
                const SizedBox(height: 20),
                _glass(
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildTimerSection(),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNativeAdSection(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildHowItWorksButton(),
                    _buildBreathingExerciseButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingExerciseButton() {
    return ThemedActionButton(
      label: 'Breathing',
      icon: Icons.self_improvement_outlined,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const BreathingExerciseScreen()),
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
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fade out at timer end'),
          subtitle:
              const Text('Gradually lower volume during the last 10 seconds'),
          value: _fadeOutEnabled,
          onChanged: (value) => setState(() => _fadeOutEnabled = value),
        ),
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
            initialMinutes:
                _remainingTime.inMinutes > 0 ? _remainingTime.inMinutes : 30,
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
    _audioService.startTimer(
      duration,
      enableFadeOut: _fadeOutEnabled,
      fadeOutDuration: const Duration(seconds: 10),
    );
    unawaited(MetricsService.instance.track(
      'timer_set',
      properties: {
        'minutes': duration.inMinutes,
        'fade_out': _fadeOutEnabled,
      },
    ));
    _sendNowPlayingUpdate();
  }

  void _cancelTimer() {
    _audioService.cancelTimer();
    unawaited(MetricsService.instance.track('timer_cancelled'));
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
