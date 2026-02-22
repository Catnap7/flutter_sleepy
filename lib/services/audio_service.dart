import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sleepy/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static const double _pinkNoiseVolumeMultiplier = 0.88;

  final AudioPlayer _player;
  final StreamController<Duration> _timerController;
  final StreamController<double> _volumeController;
  Timer? _timer;
  bool _isTimerRunning = false;
  Duration _currentDuration = Duration.zero;
  bool _enableFadeOut = true;
  Duration _fadeOutDuration = const Duration(seconds: 10);
  double _volumeBeforeFadeOut = 1.0;
  double _userVolume = 1.0;
  double _currentTrackVolumeMultiplier = 1.0;

  AudioService()
      : _player = AudioPlayer(),
        _timerController = StreamController<Duration>.broadcast(),
        _volumeController = StreamController<double>.broadcast();

  Stream<Duration> get timerStream => _timerController.stream;
  Stream<double> get volumeStream => _volumeController.stream;
  bool get isPlaying => _isTimerRunning;
  Duration get currentDuration => _currentDuration;
  double get volume => _userVolume;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidWillPauseWhenDucked: true,
    ));

    // 오디오 세션을 항상 활성 상태로 유지
    await session.setActive(true);

    // 오디오 인터럽트 핸들링 추가
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        _player.pause();
      } else {
        if (_isTimerRunning) {
          _player.play();
        }
      }
    });

    _setupAudioErrorHandling();
    _volumeController.add(_userVolume);
  }

  void _setupAudioErrorHandling() {
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('Audio playback error: $e');
        unawaited(_resetPlayerAfterLoadFailure());
      },
    );
  }

  Future<void> setTrack(Track track) async {
    try {
      await _player.setAudioSource(
        AudioSource.asset(track.assetPath),
      );
      // 반복 모드 활성화
      await _player.setLoopMode(LoopMode.all);
      _currentTrackVolumeMultiplier =
          track.id == 'pink_noise' ? _pinkNoiseVolumeMultiplier : 1.0;
      await _player.setVolume(_effectiveVolume);
    } on PlayerException catch (e) {
      debugPrint('Error loading audio source: $e');
      await _resetPlayerAfterLoadFailure();
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error while loading audio source: $e');
      await _resetPlayerAfterLoadFailure();
      rethrow;
    }
  }

  Future<void> _resetPlayerAfterLoadFailure() async {
    try {
      await _player.stop();
    } catch (_) {
      // ignore cleanup failures after a source error
    }
  }

  void setVolume(double volume) {
    _userVolume = volume.clamp(0.0, 1.0);
    _volumeController.add(_userVolume);
    unawaited(_player.setVolume(_effectiveVolume));
  }

  double get _effectiveVolume =>
      (_userVolume * _currentTrackVolumeMultiplier).clamp(0.0, 1.0);

  void _updateTimer(Duration remaining) {
    _currentDuration = remaining;
    _timerController.add(remaining);
  }

  void startTimer(
    Duration duration, {
    bool enableFadeOut = true,
    Duration fadeOutDuration = const Duration(seconds: 10),
  }) {
    _stopCurrentTimer();
    _currentDuration = duration;
    _isTimerRunning = true;
    _enableFadeOut = enableFadeOut;
    _fadeOutDuration = fadeOutDuration;
    _volumeBeforeFadeOut = _player.volume;
    _updateTimer(duration);

    // 반복 재생 시작
    _player.setLoopMode(LoopMode.all);
    _startAudioAndTimer(duration);
  }

  void _startAudioAndTimer(Duration duration) {
    _player.play();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = duration - Duration(seconds: timer.tick);
      if (remaining.inSeconds <= 0) {
        _stopCurrentTimer();
        _updateTimer(Duration.zero);
      } else {
        _applyFadeOutIfNeeded(remaining);
        _updateTimer(remaining);
      }
    });
  }

  void _applyFadeOutIfNeeded(Duration remaining) {
    if (!_enableFadeOut || _fadeOutDuration.inMilliseconds <= 0) {
      return;
    }
    if (remaining > _fadeOutDuration) {
      return;
    }
    final ratio = remaining.inMilliseconds / _fadeOutDuration.inMilliseconds;
    final targetVolume = (_volumeBeforeFadeOut * ratio).clamp(0.0, 1.0);
    _player.setVolume(targetVolume);
  }

  void _stopCurrentTimer() {
    _timer?.cancel();
    _timer = null;
    _isTimerRunning = false;
    _player.pause();
    _player.setVolume(_volumeBeforeFadeOut);
    // 타이머 종료시 반복 모드 해제
    _player.setLoopMode(LoopMode.off);
  }

  void pauseTimer() {
    if (_isTimerRunning) {
      _stopCurrentTimer();
    }
  }

  void resumeTimer() {
    if (!_isTimerRunning && _currentDuration > Duration.zero) {
      _isTimerRunning = true;
      _startAudioAndTimer(_currentDuration);
    }
  }

  void cancelTimer() {
    _stopCurrentTimer();
    _currentDuration = Duration.zero;
    _updateTimer(Duration.zero);
  }

  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _timerController.close();
    _volumeController.close();
  }

  AudioPlayer get player => _player;
}
