import 'package:flutter_sleepy/data/tracks.dart';
import 'package:flutter_sleepy/services/sound_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SoundPreferenceService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('falls back to the default track when nothing is saved', () async {
      const service = SoundPreferenceService();

      expect(
        await service.loadSelectedTrackIndex(),
        TracksData.defaultTrackIndex,
      );
    });

    test('restores a saved track by id', () async {
      const service = SoundPreferenceService();
      await service.saveSelectedTrack(TracksData.tracks[2]);

      expect(await service.loadSelectedTrackIndex(), 2);
    });

    test('ignores stale saved track ids', () async {
      SharedPreferences.setMockInitialValues({
        SoundPreferenceService.selectedTrackIdKey: 'missing_track',
      });
      const service = SoundPreferenceService();

      expect(
        await service.loadSelectedTrackIndex(),
        TracksData.defaultTrackIndex,
      );
    });
  });

  group('TracksData', () {
    test('resolves title keys independent of surrounding spaces and case', () {
      expect(TracksData.indexForTitleKey(' waves '), 2);
      expect(TracksData.indexForTitleKey('WHITE NOISE'), 5);
      expect(TracksData.indexForTitleKey('brown noise'), 6);
      expect(TracksData.indexForTitleKey('fan noise'), 7);
    });

    test('falls back to default index for unknown title keys', () {
      expect(TracksData.indexForTitleKey('green noise'), 0);
    });
  });
}
