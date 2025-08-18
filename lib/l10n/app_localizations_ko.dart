// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '포근한 잠자리';

  @override
  String get howItWorks => '사용법 안내';

  @override
  String get howItWorksSubtitle =>
      'How it works — 예측 가능한 1/f 소리로 외부 자극에 덜 깨어나도록 도와줍니다.';

  @override
  String get back => '돌아가기';

  @override
  String get playPinkNoise => '핑크 노이즈 재생';

  @override
  String get newPinkBackground => '핑크 노이즈 배경';

  @override
  String get effects_sleepQuality => '수면의 질 향상';

  @override
  String get effects_focusMemory => '집중력 및 기억력 개선';

  @override
  String get effects_tinnitus => '이명 증상 완화';

  @override
  String get effects_stress => '스트레스 감소';

  @override
  String get section_how => '작동 원리';

  @override
  String get section_tips => '사용 팁';

  @override
  String get section_faq => 'FAQ';

  @override
  String get sound_pink => '핑크 노이즈';

  @override
  String get sound_rain => '빗소리';

  @override
  String get sound_waves => '파도';

  @override
  String get sound_forest => '숲바람';

  @override
  String get sound_campfire => '모닥불';

  @override
  String get timer => '타이머';

  @override
  String get fadeOut => '서서히 줄이기';

  @override
  String minutesLeft(int minutes) {
    return '$minutes분 남음';
  }

  @override
  String soundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 사운드',
      one: '$count개 사운드',
    );
    return '$_temp0';
  }
}
