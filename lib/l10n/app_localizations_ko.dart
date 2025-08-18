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

  @override
  String get effects_sleepQuality_desc =>
      '핑크 노이즈는 깊은 수면을 유도하여 전반적인 수면의 질을 향상시킬 수 있습니다. 더 오래 자고 일어났을 때 더욱 상쾌함을 느낄 수 있습니다.';

  @override
  String get effects_focusMemory_desc =>
      '양질의 수면은 뇌의 기능을 최적화하는 데 도움이 됩니다. 특히, 핑크 노이즈는 기억력과 학습 능력 향상과 연관되어 깨어 있는 동안 더 나은 집중력을 돕습니다.';

  @override
  String get effects_tinnitus_desc =>
      '핑크 노이즈는 배경 소음으로 작용해 귀에서 들리는 불쾌한 이명을 상대적으로 덜 느끼게 할 수 있습니다.';

  @override
  String get effects_stress_desc =>
      '부드럽고 일정한 소리는 마음을 진정시키는 데 도움이 됩니다. 핑크 노이즈로 심신의 이완을 경험해 보세요.';

  @override
  String get how_bullet_1 =>
      '핑크 노이즈는 주파수 f에 대해 1/f 파워 스펙트럼을 가지며, 저주파 성분이 더 크고 고주파로 갈수록 에너지가 서서히 줄어듭니다.';

  @override
  String get how_bullet_2 =>
      '이 스펙트럼은 뇌가 예측 가능한 패턴을 인지하도록 도와, 외부의 급격한 소음 변화를 상대적으로 덜 민감하게 만듭니다.';

  @override
  String get how_bullet_3 =>
      '결과적으로 각성(arousal) 빈도를 낮추고, 깊은 수면 단계의 안정화에 기여할 수 있습니다.';

  @override
  String get tips_bullet_1 =>
      '볼륨은 낮게 시작해 천천히 올리세요. 대화 소리보다 작게, 숨소리 같은 느낌이 좋습니다.';

  @override
  String get tips_bullet_2 =>
      '수면 모드에서는 30~60분 타이머를 기본값으로 쓰고, 필요 시 전체 밤새도록 재생해 보세요.';

  @override
  String get tips_bullet_3 => '이어폰보다 스피커/수면 스피커가 편안한 경우가 많습니다.';

  @override
  String get faq_q1 => '화이트 노이즈와 무엇이 다른가요?';

  @override
  String get faq_a1 =>
      '화이트 노이즈는 모든 주파수에 동일한 파워가 분포하고, 핑크 노이즈는 1/f 형태로 저주파가 더 강합니다. 일반적으로 핑크 노이즈가 덜 날카롭고 더 자연스럽게 들립니다.';

  @override
  String get faq_q2 => '얼마나 크게 틀어야 하나요?';

  @override
  String get faq_a2 =>
      '너무 크면 오히려 각성될 수 있어요. 대화 소리보다 확실히 낮게, 존재감은 있지만 거슬리지 않는 수준이 좋습니다.';

  @override
  String get faq_q3 => '이어폰 vs 스피커?';

  @override
  String get faq_a3 => '대부분은 스피커가 더 편안합니다. 다만 소음 환경이나 개인 취향에 따라 달라질 수 있어요.';
}
