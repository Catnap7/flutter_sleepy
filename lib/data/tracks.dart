import 'package:flutter_sleepy/models/track.dart';

class TracksData {
  static const List<Track> tracks = [
    Track(
        id: 'rain_noise',
        title: "Rainy",
        assetPath: "assets/audio/rain_noise.wav"
    ),
    Track(
        id: 'pink_noise',
        title: "Waves",
        assetPath: "assets/audio/wave.mp3"
    ),
    Track(
        id: 'fire_noise',
        title: "Camp Fire",
        assetPath: "assets/audio/fire_noise.wav"
    ),
  ];
}