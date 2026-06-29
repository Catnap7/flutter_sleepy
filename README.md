# Sleepy – Bedtime Sound App (Flutter)

Sleepy plays offline calming sounds with a sleep timer that keeps playing in the background and stops at the set time. It is positioned as a quiet, no-account, no-ads bedtime utility.

## Run locally

Prerequisites:
- Flutter SDK (stable channel)
- Android Studio/Xcode for device simulators and platform SDKs

Commands:
1. flutter pub get
2. flutter run

Notes:
- On first launch on Android, you may be prompted to allow ignoring battery optimizations for stable background playback.
- Background service notification will show current state (Ready / Playing / remaining time).

## Tests

This repo contains a minimal widget smoke test and a pure-Dart unit test.

Run all tests:
- flutter test

Files:
- test/widget_test.dart – verifies the home title renders
- test/duration_formatter_test.dart – verifies DurationFormatter formatting
- test/sound_preference_service_test.dart – verifies last-used sound restore

## Troubleshooting

- If Android build fails in non-Flutter-aware environments, build locally with Flutter tools:
  - flutter clean && flutter pub get && flutter build apk
- For iOS, open ios/Runner.xcworkspace in Xcode and run on a device/simulator.

## About
- Offline sleep sounds: Rain, Pink Noise, White Noise, Brown Noise, Fan Noise, Waves, Camp Fire, Thunderstorm.
- Sleep timer presets, custom timer, and fade-out at timer end.
- Dark-first UI, Material 3, large tap targets, accessible labels.
- Background playback via flutter_background_service.
- Audio via just_audio.
