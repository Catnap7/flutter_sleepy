import 'package:flutter_sleepy/models/track.dart';

class TracksData {
  static const List<Track> tracks = [
    Track(
      id: 'rain_noise',
      title: 'Rainy',
      assetPath: 'assets/audio/rain_noise.mp3',
    ),
    Track(
      id: 'pink_noise',
      title: 'Pink Noise',
      assetPath: 'assets/audio/pink_noise.mp3',
      volumeMultiplier: 0.88,
    ),
    Track(
      id: 'wave_noise',
      title: 'Waves',
      assetPath: 'assets/audio/wave.mp3',
    ),
    Track(
      id: 'fire_noise',
      title: 'Camp Fire',
      assetPath: 'assets/audio/fire_noise.mp3',
    ),
    Track(
      id: 'thunder_noise',
      title: 'Thunderstorm',
      assetPath: 'assets/audio/thunder_noise.mp3',
      volumeMultiplier: 0.82,
    ),
    Track(
      id: 'white_noise',
      title: 'White Noise',
      assetPath: 'assets/audio/white_noise.mp3',
      volumeMultiplier: 0.65,
    ),
    Track(
      id: 'brown_noise',
      title: 'Brown Noise',
      assetPath: 'assets/audio/brown_noise.mp3',
      volumeMultiplier: 0.86,
    ),
    Track(
      id: 'fan_noise',
      title: 'Fan Noise',
      assetPath: 'assets/audio/fan_noise.mp3',
      volumeMultiplier: 0.78,
    ),
  ];

  static const int defaultTrackIndex = 0;

  static int? indexForId(String? id) {
    if (id == null) {
      return null;
    }
    final index = tracks.indexWhere((track) => track.id == id);
    return index >= 0 ? index : null;
  }

  static int indexForTitleKey(String key) {
    final normalizedKey = key.trim().toLowerCase();
    final index = tracks.indexWhere(
      (track) => track.title.toLowerCase() == normalizedKey,
    );
    return index >= 0 ? index : defaultTrackIndex;
  }
}
