// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cozy Sleep';

  @override
  String get howItWorks => 'How It Works';

  @override
  String get howItWorksSubtitle =>
      'How it works — predictable 1/f sound helps reduce awakenings.';

  @override
  String get back => 'Back';

  @override
  String get playPinkNoise => 'Play Pink Noise';

  @override
  String get newPinkBackground => 'Pink Noise background';

  @override
  String get effects_sleepQuality => 'Better sleep quality';

  @override
  String get effects_focusMemory => 'Improved focus & memory';

  @override
  String get effects_tinnitus => 'Tinnitus relief';

  @override
  String get effects_stress => 'Stress reduction';

  @override
  String get section_how => 'How it works';

  @override
  String get section_tips => 'Tips';

  @override
  String get section_faq => 'FAQ';

  @override
  String get sound_pink => 'Pink Noise';

  @override
  String get sound_rain => 'Rain';

  @override
  String get sound_waves => 'Waves';

  @override
  String get sound_forest => 'Forest Breeze';

  @override
  String get sound_campfire => 'Campfire';

  @override
  String get timer => 'Timer';

  @override
  String get fadeOut => 'Fade out';

  @override
  String minutesLeft(int minutes) {
    return '$minutes min left';
  }

  @override
  String soundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sounds',
      one: '$count sound',
    );
    return '$_temp0';
  }

  @override
  String get effects_sleepQuality_desc =>
      'Pink noise can encourage deeper sleep and improve overall sleep quality. You may sleep longer and wake feeling more refreshed.';

  @override
  String get effects_focusMemory_desc =>
      'Quality sleep optimizes brain function. Pink noise is associated with improved memory and learning, helping better focus when awake.';

  @override
  String get effects_tinnitus_desc =>
      'Pink noise can act as gentle background sound that makes intrusive ringing less noticeable.';

  @override
  String get effects_stress_desc =>
      'Soft, steady sound helps calm the mind. Try pink noise to relax body and mind.';

  @override
  String get how_bullet_1 =>
      'Pink noise features a 1/f power spectrum: stronger low frequencies and gradually decreasing energy toward higher frequencies.';

  @override
  String get how_bullet_2 =>
      'This spectral profile helps the brain perceive predictable patterns, making sudden external noises feel less disruptive.';

  @override
  String get how_bullet_3 =>
      'As a result, it can reduce arousal frequency and help stabilize deeper sleep stages.';

  @override
  String get tips_bullet_1 =>
      'Start with low volume and increase slowly. Aim for softer than conversation, like a gentle breath.';

  @override
  String get tips_bullet_2 =>
      'For sleep mode, try a 30–60 minute timer by default; play all night if needed.';

  @override
  String get tips_bullet_3 =>
      'Speakers or sleep speakers are often more comfortable than earphones.';

  @override
  String get faq_q1 => 'How is it different from white noise?';

  @override
  String get faq_a1 =>
      'White noise distributes equal power across frequencies, while pink noise follows 1/f with stronger lows. Pink noise often sounds less sharp and more natural.';

  @override
  String get faq_q2 => 'How loud should I set it?';

  @override
  String get faq_a2 =>
      'Too loud can be counterproductive. Keep it clearly below conversation level—present but never distracting.';

  @override
  String get faq_q3 => 'Earphones vs speakers?';

  @override
  String get faq_a3 =>
      'Most people find speakers more comfortable, but it depends on your noise environment and personal preference.';
}
