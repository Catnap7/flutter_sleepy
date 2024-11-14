import 'package:flutter_sleepy/models/track.dart';

class TracksData {
  static const List<Track> tracks = [
    Track(
        id: 'rain_noise',
        title: "빗소리",
        assetPath: "assets/audio/rain_noise.wav"
    ),
    Track(
        id: 'pink_noise',
        title: "핑크노이즈",
        assetPath: "assets/audio/pink_noise.wav"
    ),
    Track(
        id: 'fire_noise',
        title: "모닥불",
        assetPath: "assets/audio/fire_noise.wav"
    ),
  ];
}