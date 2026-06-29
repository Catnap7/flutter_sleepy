# Play Console Update Packet

Use this packet for the next Sleepy store-listing update.

## Priority 1: policy and trust alignment

- Release build: `1.0.4+5`
- Release AAB: `docs/store/play_release_1.0.4_5/Sleepy-1.0.4+5.aab`
- AAB size: `69.4 MB` (`66M` on disk)
- SHA-256: `6d3074f173e98b25e241f42a40043c053ac10c4e122f8fd0080da6a51634e04b`
- Ads declaration: `No, my app does not contain ads`
- Data safety: `No data collected`
- App access: `No restricted access`
- Target audience: adults/general users, not specifically directed at children
- Medical claims: do not claim diagnosis, treatment, cure, or guaranteed sleep improvement

This repository version removes the AdMob SDK and ad placements so the public `No ads` position is true in the app binary.

The release also replaces broken placeholder audio files, compresses the largest WAV assets to MP3, remembers the last selected sound, adds brown noise and fan noise, and shows battery optimization status on the home screen.

## Priority 2: ASO metadata

### English

- App name: `Sleepy: Sleep Sounds Timer`
- Short description: `Offline rain, white noise, and fade-out sleep timer.`

### Korean

- App name: `슬리피: 수면 소리 타이머`
- Short description: `비, 백색소음, 수면 타이머를 오프라인으로 조용하게 들으세요.`

## Priority 3: screenshots

Replace the current screenshots with six portrait phone screenshots at `1080x1920` or another Play-accepted portrait size.

Upload-ready files are in `docs/store/play_upload_2026_05/`:

1. `01_offline_sleep_sounds.png`
2. `02_fade_out_timer.png`
3. `03_background_audio.png`
4. `04_bedtime_controls.png`
5. `05_breathing.png`
6. `06_no_account.png`

Recommended order:

1. `Offline sleep sounds`
2. `Fade-out sleep timer`
3. `Keeps playing with screen off`
4. `One-tap bedtime controls`
5. `4-7-8 breathing`
6. `No account required`

Avoid screenshots that claim sound mixing until the app actually supports multi-sound mixing.

The upload-ready set was generated from `docs/store/raw_sources/play_current/` with `docs/store/scripts/generate_play_upload_assets.py` and validated against Google Play image constraints.

## Priority 4: next feature work

If the next product update is allowed, add these before claiming them in the store:

1. Real multi-sound mixer with individual volume controls
2. Review prompt only after a completed timer session
