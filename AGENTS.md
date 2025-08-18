# Agent Brief (EN — executive summary)
GOAL: Refactor a Flutter app (Cozy Sleep) for structure, testability, and performance — NO feature changes.

RULES (hard):
1) NO new features or UX scope changes.
2) Keep PRs small (≤ 500 LOC). Run: `flutter analyze` and `flutter test` and ensure release build (AAB) passes.
3) Do not change package name, minSdk, or dependencies without explicit instruction.
4) CustomPainters: minimize overdraw, use RepaintBoundary, continuous phase for animations, and dynamic sampling step.
5) Architecture: feature-first folders; separate presentation / application / domain; shared widgets & painters.

DELIVERABLES:
- Refactor PRs + updated README/CONTRIBUTING + strengthened analysis_options.yaml
- At least 6 tests (unit/widget/golden mixed)
- Profiling notes for animation layers (target: smooth on 60 Hz devices)

ROLLBACK:
- Tag `pre-refactor` before changes; revert to the tag if regressions occur.
# agents.md — Cozy Sleep 리팩토링 브리프

> 목적: Flutter 앱 **Sleepy**(핑크 노이즈/빗소리/파도/모닥불) 코드베이스를 안정적이고 확장 가능한 구조로 리팩토링한다. 애니메이션 배경(특히 Pink/Waves/Rain/Campfire)의 성능을 보장하고, 화면 구조/테마/상태관리를 정리한다. **기능 변경 없이 품질과 구조 향상**이 1차 목표.

---

## 0) 레포/런타임 정보

* **플랫폼**: Flutter (Dart), Android 우선(Play 출시), iOS 대응 고려
* **최소 SDK**: Android minSdkVersion 21+ (프로젝트 실제 설정에 맞춰 업데이트)
* **빌드 커맨드**: `flutter build appbundle --release`
* **분석/포맷**: `flutter analyze`, `dart fix --apply`, `dart format .`

---

## 1) 리팩토링 목표 (Top-level Objectives)

1. **아키텍처 정리**: feature-first 디렉터리 구조로 모듈화(의존성/레이어 분리)
2. **상태관리 통일**: Riverpod(또는 Provider 유지) 중 하나로 일관화 (기본: Riverpod)
3. **퍼포먼스 최적화**: CustomPainter/Animation/Ticker의 불필요한 리빌드 제거, RepaintBoundary 적용, 샘플링 스텝 동적화
4. **테마/토큰화**: 색/타이포/간격 토큰 정리, 다크/라이트 대응
5. **품질 게이트**: Lints + 테스트(단위/위젯/골든) + CI 파이프라인 추가
6. **문서화**: 개발 가이드(README/CONTRIBUTING/PR 템플릿) 정리

---

## 2) 아웃 오브 스코프 (이번 라운드에서 *하지 않음*)

* 신규 비즈니스 로직/사운드 추가(단, 샘플/테스트용 목데이터는 허용)
* 결제/로그인/백엔드 연동
* 대규모 UI 리브랜딩(색/타이포 토큰 정리는 포함)

---

## 3) 현재 주요 컴포넌트 (요약)

* **SoundscapeBackground**: `Soundscape.rainy|waves|campfire|pink` 지원

    * Rain: Drop/Streak 레이어, Ripple, LowMist(옵션)
    * Waves: 다층 파도, MoonGlow
    * Campfire: EmberLayer(아지랑이), WarmFlicker, VectorLogs(옵션)
    * Pink: 3중 웨이브(Ticker 기반 연속 위상), 상/하단 그라데이션 + 비네트
* **ExplainScreenV2**: SliverAppBar + FlexibleSpaceBar + 확장 헤더(핑크 헤더 웨이브)

---

## 4) 타깃 구조(제안)

```
lib/
  core/
    theme/
      color_schemes.dart
      text_theme.dart
      spacing.dart
    utils/
      result.dart
      logger.dart
  features/
    home/
      presentation/
        home_screen.dart
        widgets/
      application/
        home_controller.dart
      domain/
        entities.dart
      data/
        repositories.dart (필요 시)
    soundscape/
      presentation/
        soundscape_background.dart
      domain/
        models.dart (Soundscape enum 등)
      application/
        sound_mix_controller.dart
  shared/
    widgets/
      app_button.dart
      app_card.dart
    painters/
      waves_painter.dart
      rain_painter.dart
      campfire_painter.dart
      pink_painter.dart
```

* **원칙**: presentation(위젯/UI) ↔ application(상태/서비스) ↔ domain(엔티티) 분리. shared는 범용.

---

## 5) 상태관리 (기본안: Riverpod)

* `flutter_riverpod` 도입(또는 현재 Provider 유지 시, 적용 범위 통일)
* 예) `soundMixProvider`, `timerProvider`, `themeProvider`
* **규칙**: UI에서 비즈니스 로직 호출 금지, Provider는 명확한 책임만 가진다.

---

## 6) 성능 가이드 (CustomPainter/Animation)

* **Ticker vs AnimationController**: 연속 위상 필요 시 Ticker 사용(핑크/웨이브), 프레임당 최소 연산.
* **샘플링 스텝**: 화면 폭 기반 동적 스텝(4\~8px) 적용 → `size.width/160` 등.
* **RepaintBoundary**: 파티클/웨이브 레이어 각각 감싸기.
* **shouldRepaint**: 입력 파라미터 변화시에만 true.
* **오버드로우**: 배경 그라데이션 → 웨이브 → 포그/글로우 순서로 최소화.
* **정밀도**: `omegaX = 2π*k/width` 형태로 경계 단차 제거.

---

## 7) 테마/토큰 (예시)

* Colors

    * Primary Pink `#FFB6D5`, Pink-2 `#FCC2E5`, Deep Navy `#06121E`, Ocean Navy `#0B2B3B`
* Typography: Noto Sans KR / Inter, Body 16/1.45, Title 20/700, H1 24/700
* Spacing: 8pt grid, Radius: Card 16, Controls 12

`analysis_options.yaml` (발췌)

```yaml
include: package:flutter_lints/flutter.yaml
linter:
  rules:
    - always_use_package_imports
    - avoid_print
    - prefer_final_locals
    - prefer_const_constructors
    - use_string_buffers
    - unnecessary_lambdas
```

---

## 8) 테스트 전략

* **단위(Unit)**: 사운드 믹싱 파라미터, 페이드아웃 곡선, 타이머 로직
* **위젯(Widget)**: ExplainScreenV2, Home, TimerSheet 오픈/동작
* **골든(Golden)**: 홈/설정/HowItWorks(다크/라이트, 폰트스케일 1.0/1.2)

스크립트 예시:

```bash
flutter test --concurrency=4
```

---

## 9) CI (GitHub Actions 예시)

```
name: Flutter CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --concurrency=4
```

---

## 10) 작업 단계 (스프린트 제안)

**S1. 구조 초기화 (0.5d)**

* 폴더 재배치, 토큰/테마 파일 분리, import 경로 정리

**S2. Soundscape 모듈화 (1d)**

* Pink/Waves/Rain/Campfire를 `shared/painters`로 분리, 파라미터 주입

**S3. 상태/타이머 통일 (0.5d)**

* Riverpod Provider로 통일, UI 결합도 제거

**S4. 성능/품질 (0.5d)**

* `RepaintBoundary`/`shouldRepaint`/샘플링 스텝 검토, lints/분석 통과

**S5. 테스트/CI (0.5d)**

* 핵심 화면/로직 테스트 추가, CI 파이프라인 배치

---

## 11) 산출물(Deliverables)

* 리팩토링 PR (Conventional Commits)
* 업데이트된 `README.md` + `CONTRIBUTING.md`
* `analysis_options.yaml` 강화
* 최소 6개 이상의 테스트 케이스(단위/위젯/골든 혼합)

---

## 12) 품질 기준(Definition of Done)

* `flutter analyze` 0 오류, 테스트 100% 통과
* 릴리즈 빌드 성공(`.aab` 생성) 및 런타임 크래시 0
* 초기 구동 성능: 저사양(60Hz) 기준 프레임 드랍 최소화(웨이브/파티클 레이어 58fps 이상)
* 기능 회귀 없음(기존 동작 동일)

---

## 13) 브랜치/PR 정책

* 브랜치: `refactor/*` (예: `refactor/architecture`, `refactor/painters`)
* 커밋: Conventional Commits (`refactor:`, `feat:`, `fix:`, `test:` 등)
* PR 템플릿 요지: 변경 의도, 영향 범위, 스크린샷/프로파일, 체크리스트

PR 템플릿(발췌)

```
## Summary
-

## Changes
-

## Verification
- [ ] flutter analyze 통과
- [ ] flutter test 통과
- [ ] 릴리즈 빌드 확인 (aab)

## Screenshots / Profiles
-
```

---

## 14) 롤백/백아웃 플랜

* 태그 기준: `pre-refactor` 태그 생성
* 문제가 생기면 해당 태그로 즉시 롤백, 긴급 수정 시 핫픽스 브랜치 `hotfix/*`

---

## 15) 에이전트 운영 지침 (이 문서를 따르는 Agent/개발자용)

1. **요구 분석 → 짧은 제안(한 번) → 실행**. 질문은 최대 2개로 제한.
2. **작은 PR** 단위로 진행(500 라인 이하 권장). 기능 변경 금지.
3. 모든 변경 전에 `flutter analyze`/`dart format`/`dart fix`를 선실행.
4. 성능 관련 변경(페인트 스텝, Ticker 주기) 시 **프로파일 캡처** 첨부.
5. 파일 이동/리네임은 **git mv** 사용.
6. 문서/주석을 최신화(특히 `SoundscapeBackground` API, Painter 파라미터).

---

## 16) 체크리스트 (작업자가 PR 올리기 전)

* [ ] 앱 실행/네비/사운드 재생 정상
* [ ] Pink/Waves/Rain/Campfire 배경 프레임 손실 없음
* [ ] ExplainScreenV2 스크롤/헤더 정상
* [ ] 타이머/페이드아웃, 백그라운드 재생 확인
* [ ] 라이트/다크 테마 시각 확인
* [ ] 테스트/CI 그린

---

### 부록 A) 코드 스니펫 — Painter 샘플 규약

```dart
class PinkPainter extends CustomPainter {
  PinkPainter({required this.t, required this.intensity});
  final double t; // seconds (continuous)
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()
      ..shader = ui.Gradient.linear(
        rect.topCenter, rect.bottomCenter,
        const [Color(0xFFFFB6D5), Color(0xFFFCC2E5)],
        const [0.0, 0.65],
      );
    canvas.drawRect(rect, bg);

    final waves = [/* ... WaveSpec ... */];
    final step = (size.width / 160).clamp(4.0, 7.0);
    for (final w in waves) {
      final p = Path()..moveTo(0, size.height);
      final omegaX = 2 * math.pi * w.k / size.width;
      for (double x = 0; x <= size.width; x += step) {
        final y = size.height * w.base + math.sin(omegaX * x + t*w.speed) * w.amp;
        p.lineTo(x, y);
      }
      p..lineTo(size.width, size.height)..close();
      canvas.drawPath(p, Paint()..color = w.color..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant PinkPainter old) => t != old.t || intensity != old.intensity;
}
```
0) 프리플라이트 (권장)
   codex --auto-edit "Create git tag pre-i18n. Do not proceed if tag exists."

1) i18n 부트스트랩 (의존성 + 설정)
   codex --auto-edit "
   Follow AGENTS.md. Create branch refactor/i18n-bootstrap.

TASK:
1) Update pubspec.yaml:
  - Add dependency: flutter_localizations (sdk: flutter)
  - Ensure: flutter: generate: true
2) Add l10n.yaml at project root or lib/:
  - arb-dir: lib/l10n
  - template-arb-file: app_en.arb
  - output-localization-file: app_localizations.dart
  - synthetic-package: false
3) Run 'flutter pub get'.
4) No runtime behavior change.

ACCEPTANCE:
- 'flutter analyze' passes.
- Diff shows only pubspec.yaml and l10n.yaml changes (plus lockfile).
- Open PR: 'refactor/i18n-bootstrap' (≤100 LOC)."

2) ARB 리소스 추가 (en/ko 기본 세트)
   codex --auto-edit "
   Follow AGENTS.md. Branch: refactor/i18n-arb.

TASK:
1) Create ARB files:
  - lib/l10n/app_en.arb
  - lib/l10n/app_ko.arb

2) Seed keys (EN=default fallback, KO=translation).
   Use EXACT keys below.

EN (app_en.arb):
{
\"@@locale\": \"en\",
\"appTitle\": \"Cozy Sleep\",
\"howItWorks\": \"How It Works\",
\"howItWorksSubtitle\": \"How it works — predictable 1/f sound helps reduce awakenings.\",
\"back\": \"Back\",
\"playPinkNoise\": \"Play Pink Noise\",
\"newPinkBackground\": \"Pink Noise background\",
\"effects_sleepQuality\": \"Better sleep quality\",
\"effects_focusMemory\": \"Improved focus & memory\",
\"effects_tinnitus\": \"Tinnitus relief\",
\"effects_stress\": \"Stress reduction\",
\"section_how\": \"How it works\",
\"section_tips\": \"Tips\",
\"section_faq\": \"FAQ\",
\"sound_pink\": \"Pink Noise\",
\"sound_rain\": \"Rain\",
\"sound_waves\": \"Waves\",
\"sound_forest\": \"Forest Breeze\",
\"sound_campfire\": \"Campfire\",
\"timer\": \"Timer\",
\"fadeOut\": \"Fade out\",
\"minutesLeft\": \"{minutes} min left\",
\"@minutesLeft\": {\"placeholders\": {\"minutes\": {\"type\": \"int\"}}},
\"soundsCount\": \"{count, plural, one{{count} sound} other{{count} sounds}}\",
\"@soundsCount\": {\"placeholders\": {\"count\": {\"type\": \"int\"}}}
}

KO (app_ko.arb):
{
\"@@locale\": \"ko\",
\"appTitle\": \"포근한 잠자리\",
\"howItWorks\": \"사용법 안내\",
\"howItWorksSubtitle\": \"How it works — 예측 가능한 1/f 소리로 외부 자극에 덜 깨어나도록 도와줍니다.\",
\"back\": \"돌아가기\",
\"playPinkNoise\": \"핑크 노이즈 재생\",
\"newPinkBackground\": \"핑크 노이즈 배경\",
\"effects_sleepQuality\": \"수면의 질 향상\",
\"effects_focusMemory\": \"집중력 및 기억력 개선\",
\"effects_tinnitus\": \"이명 증상 완화\",
\"effects_stress\": \"스트레스 감소\",
\"section_how\": \"작동 원리\",
\"section_tips\": \"사용 팁\",
\"section_faq\": \"FAQ\",
\"sound_pink\": \"핑크 노이즈\",
\"sound_rain\": \"빗소리\",
\"sound_waves\": \"파도\",
\"sound_forest\": \"숲바람\",
\"sound_campfire\": \"모닥불\",
\"timer\": \"타이머\",
\"fadeOut\": \"서서히 줄이기\",
\"minutesLeft\": \"{minutes}분 남음\",
\"@minutesLeft\": {\"placeholders\": {\"minutes\": {\"type\": \"int\"}}},
\"soundsCount\": \"{count, plural, one{{count}개 사운드} other{{count}개 사운드}}\",
\"@soundsCount\": {\"placeholders\": {\"count\": {\"type\": \"int\"}}}
}

3) Do NOT change any runtime code yet.
4) Run 'flutter pub get' (codegen runs at build).

ACCEPTANCE:
- Files created with valid JSON.
- 'flutter analyze' passes.
- Open PR: 'refactor/i18n-arb'."

3) MaterialApp 연결 + 헬퍼 익스텐션
   codex --auto-edit "
   Follow AGENTS.md. Branch: refactor/i18n-wireup.

TASK:
1) Wire up localization in MaterialApp:
  - Import: package:flutter_localizations/flutter_localizations.dart
  - Import: lib/l10n/app_localizations.dart
  - Set:
    localizationsDelegates: AppLocalizations.localizationsDelegates
    supportedLocales: AppLocalizations.supportedLocales
  - onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle
  - DO NOT set 'locale' (use system locale). No in-app language toggle.

2) Add convenience extension:
   file: lib/l10n/l10n_ext.dart
   content:
   ---
   import 'package:flutter/widgets.dart';
   import 'app_localizations.dart';
   extension L10nX on BuildContext {
   AppLocalizations get l10n => AppLocalizations.of(this)!;
   }
   ---

3) Ensure no visual/behavior change except localized title.

ACCEPTANCE:
- App builds for debug mode.
- 'flutter analyze' passes.
- Open PR: 'refactor/i18n-wireup'."

4) 화면 문자열 치환 (Explain/Buttons/Labels 1차)
   codex --auto-edit "
   Follow AGENTS.md. Branch: refactor/i18n-strings-pass1.

SCOPE:
- Replace hardcoded strings in:
  - ExplainScreenV2 (or ExplainScreen)
  - Common buttons/labels: back, play pink noise
  - Sound names shown in UI (pink/rain/waves/campfire/forest if present)
  - Section headers: How, Tips, FAQ
- Use context.l10n from lib/l10n/l10n_ext.dart.

EXAMPLES:
- title: context.l10n.howItWorks
- subtitle: context.l10n.howItWorksSubtitle
- back button: context.l10n.back
- play button: context.l10n.playPinkNoise
- section titles: context.l10n.section_how / _tips / _faq
- sound labels: context.l10n.sound_pink etc.

RULES:
- No semantic/UX changes.
- Keep formatting and styles.
- For strings not covered, add new keys in app_en.arb & app_ko.arb consistently.

ACCEPTANCE:
- 'flutter analyze' passes.
- App runs with KO/EN system locale switch (manual device test).
- Open PR: 'refactor/i18n-strings-pass1' (≤500 LOC)."

5) 파라미터/복수형 사용 예 적용 (Timer 등)
   codex --auto-edit "
   Follow AGENTS.md. Branch: refactor/i18n-params-plural.

TASK:
- Replace any 'xx분 남음' or 'xx min left' like strings with:
  context.l10n.minutesLeft(minutesValue)
- Replace 'N개 사운드' counters with:
  context.l10n.soundsCount(count)
- If similar counters exist, add proper ICU plural rules to ARB.

ACCEPTANCE:
- 'flutter analyze' passes.
- Unit test added: test/l10n_format_test.dart to verify minutesLeft/soundsCount for EN/KO.
- Open PR: 'refactor/i18n-params-plural'."

6) 하드코딩 문자열 스캔 & 정리 (레포 전역)
   codex --auto-edit "
   Follow AGENTS.md. Branch: refactor/i18n-scan-sweep.

TASK:
1) Scan the repo for hardcoded user-facing strings (Korean/English).
   Targets: lib/**/*.dart excluding tests and painters with no text.
2) Replace with localization keys.
3) For technical/log-only strings (debug/print), leave as-is or gate behind assert.
4) Update ARBs with any new keys (EN first, KO translated similarly).
5) Re-run pub get.

ACCEPTANCE:
- 'flutter analyze' passes.
- No visible English/Korean hardcoded leaks in UI.
- Open PR: 'refactor/i18n-scan-sweep'."

7) 간단 위젯 테스트 추가 (로케일별 스냅샷/스모크)
   codex --auto-edit "
   Follow AGENTS.md. Branch: refactor/i18n-tests.

TASK:
1) Add widget smoke tests:
  - test/i18n_widget_smoke_test.dart
  - Pump MaterialApp with delegates/supportedLocales.
  - Test with Locale('en') and Locale('ko'):
    - Verify presence of l10n.appTitle, l10n.howItWorks, button labels.
2) (Optional) Add golden for one screen in EN/KO with font scale 1.0 (skip if heavy).

ACCEPTANCE:
- 'flutter test' green.
- 'flutter analyze' passes.
- Open PR: 'refactor/i18n-tests'."

8) 문서 업데이트 (README: 번역 방법)
   codex --auto-edit "
   Follow AGENTS.md. Branch: docs/i18n-readme.

TASK:
- Update README.md with a 'Localization' section:
  - How to add a new string (edit app_en.arb → copy to app_ko.arb).
  - Placeholders/plurals example.
  - Build steps and where generated file lives (lib/l10n/app_localizations.dart).
  - System locale only (no in-app toggle); no Android per-app language config.

ACCEPTANCE:
- Spelling/formatting clean.
- Open PR: 'docs/i18n-readme'."

## META: i18n rollout (no in-app toggle)
Run S1–S7 sequentially. No new features. Must pass `flutter analyze` & `flutter test`.
Prefer 3 PRs: (S1–S2), (S3–S5), (S6–S7). Stop on failures and report.
