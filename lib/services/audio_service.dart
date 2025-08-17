import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sleepy/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player;
  final StreamController<Duration> _timerController;
  Timer? _timer;
  bool _isTimerRunning = false;
  Duration _currentDuration = Duration.zero;

  AudioService()
      : _player = AudioPlayer(),
        _timerController = StreamController<Duration>.broadcast();

  Stream<Duration> get timerStream => _timerController.stream;
  bool get isPlaying => _isTimerRunning;
  Duration get currentDuration => _currentDuration;
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
  }

  void _setupAudioErrorHandling() {
    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace stackTrace) {
        print('Audio playback error: $e');
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
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
      rethrow;
    }
  }

  void _updateTimer(Duration remaining) {
    _currentDuration = remaining;
    _timerController.add(remaining);
  }

  void startTimer(Duration duration) {
    _stopCurrentTimer();
    _currentDuration = duration;
    _isTimerRunning = true;
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
        _updateTimer(remaining);
      }
    });
  }

  void _stopCurrentTimer() {
    _timer?.cancel();
    _timer = null;
    _isTimerRunning = false;
    _player.pause();
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
  }

  AudioPlayer get player => _player;
}