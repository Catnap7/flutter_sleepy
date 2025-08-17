# Sleepy – Bedtime Sound App (Flutter)

Sleepy plays calming sounds (Rain, Pink Noise, Fire) with a sleep timer that keeps playing in the background and stops at the set time.

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

## Troubleshooting

- If Android build fails in non-Flutter-aware environments, build locally with Flutter tools:
  - flutter clean && flutter pub get && flutter build apk
- For iOS, open ios/Runner.xcworkspace in Xcode and run on a device/simulator.

## About
- Dark-first UI, Material 3, large tap targets, accessible labels.
- Background playback via flutter_background_service.
- Audio via just_audio.
