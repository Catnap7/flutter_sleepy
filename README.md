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

## Architecture (S1–S3 Progress)

- Core theme tokens moved under `lib/core/theme/`:
  - `color_schemes.dart`, `text_theme.dart`, `spacing.dart`
- Theme composition remains in `lib/theme/app_theme.dart` (no visual changes).
- Lints strengthened in `analysis_options.yaml` to enforce package imports and code hygiene.
- S2 (in progress): feature-first entry points added:
  - `lib/features/soundscape/presentation/soundscape_background.dart` (re-exports current background)
  - `lib/features/soundscape/domain/models.dart` (re-exports Soundscape enum)
  - `lib/features/home/presentation/home_screen.dart` (re-exports AudioHomePage)
  - Next small PR: migrate painter implementations from `utils/soundscapes.dart` into `shared/painters/*` classes.
- S3 (scoped, no deps change): maintain current ChangeNotifier pattern; unify wiring gradually without adding packages.

## Troubleshooting

- If Android build fails in non-Flutter-aware environments, build locally with Flutter tools:
  - flutter clean && flutter pub get && flutter build apk
- For iOS, open ios/Runner.xcworkspace in Xcode and run on a device/simulator.

## About
- Dark-first UI, Material 3, large tap targets, accessible labels.
- Background playback via flutter_background_service.
- Audio via just_audio.
 
## Localization

- Source files: `lib/l10n/app_en.arb` (default) and `lib/l10n/app_ko.arb`.
- Generated API: `lib/l10n/app_localizations.dart` (configured via `l10n.yaml`).
- Wire-up: `MaterialApp` sets `localizationsDelegates` and `supportedLocales` from `AppLocalizations`.
- Usage in widgets: `import 'package:flutter_sleepy/l10n/l10n_ext.dart';` then `context.l10n.key`.

Add a new string
- Edit `lib/l10n/app_en.arb` with a new key/value.
- Copy the key to `lib/l10n/app_ko.arb` with the translated value.
- Placeholders: ICU style, e.g. `"minutesLeft": "{minutes} min left"` with `@minutesLeft` placeholders.
- Plurals: ICU plural, e.g. `"soundsCount": "{count, plural, one{{count} sound} other{{count} sounds}}"`.

Build/generate
- Run `flutter pub get` (codegen runs automatically) or `flutter gen-l10n`.
- No in-app language toggle; the system locale is used.
