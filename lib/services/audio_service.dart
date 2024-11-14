import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_sleepy/models/track.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player;
  final StreamController<Duration> _timerController;
  Timer? _timer;

  AudioService():
        _player = AudioPlayer(),
        _timerController = StreamController<Duration>.broadcast();

  Stream<Duration> get timerStream => _timerController.stream;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playbackEventStream.listen(
            (_) {},
        onError: (Object e, StackTrace stackTrace) {
          print('Audio playback error: $e');
        }
    );
  }

  Future<void> setTrack(Track track) async {
    try {
      await _player.setAudioSource(AudioSource.asset(track.assetPath));
    } on PlayerException catch (e) {
      print("Error loading audio source: $e");
      rethrow;
    }
  }

  void startTimer(Duration duration) {
    _timer?.cancel();
    _timerController.add(duration);
    _player.play();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = duration - Duration(seconds: timer.tick);
      if (remaining.inSeconds <= 0) {
        timer.cancel();
        _player.pause();
        _timerController.add(Duration.zero);
      } else {
        _timerController.add(remaining);
      }
    });
  }

  void cancelTimer() {
    _timer?.cancel();
    _timerController.add(Duration.zero);
  }

  void dispose() {
    _timer?.cancel();
    _player.dispose();
    _timerController.close();
  }

  AudioPlayer get player => _player;
}
