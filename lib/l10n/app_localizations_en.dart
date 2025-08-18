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
}
