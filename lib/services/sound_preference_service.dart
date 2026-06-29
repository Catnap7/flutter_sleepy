import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundPreferenceService {
  const SoundPreferenceService();

  static const selectedTrackIdKey = 'selected_track_id_v1';

  Future<int> loadSelectedTrackIndex() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTrackId = preferences.getString(selectedTrackIdKey);
    return TracksData.indexForId(savedTrackId) ?? TracksData.defaultTrackIndex;
  }

  Future<void> saveSelectedTrack(Track track) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(selectedTrackIdKey, track.id);
  }
}
