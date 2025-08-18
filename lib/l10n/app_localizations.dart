import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Cozy Sleep'**
  String get appTitle;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @howItWorksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How it works — predictable 1/f sound helps reduce awakenings.'**
  String get howItWorksSubtitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @playPinkNoise.
  ///
  /// In en, this message translates to:
  /// **'Play Pink Noise'**
  String get playPinkNoise;

  /// No description provided for @newPinkBackground.
  ///
  /// In en, this message translates to:
  /// **'Pink Noise background'**
  String get newPinkBackground;

  /// No description provided for @effects_sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Better sleep quality'**
  String get effects_sleepQuality;

  /// No description provided for @effects_focusMemory.
  ///
  /// In en, this message translates to:
  /// **'Improved focus & memory'**
  String get effects_focusMemory;

  /// No description provided for @effects_tinnitus.
  ///
  /// In en, this message translates to:
  /// **'Tinnitus relief'**
  String get effects_tinnitus;

  /// No description provided for @effects_stress.
  ///
  /// In en, this message translates to:
  /// **'Stress reduction'**
  String get effects_stress;

  /// No description provided for @section_how.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get section_how;

  /// No description provided for @section_tips.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get section_tips;

  /// No description provided for @section_faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get section_faq;

  /// No description provided for @sound_pink.
  ///
  /// In en, this message translates to:
  /// **'Pink Noise'**
  String get sound_pink;

  /// No description provided for @sound_rain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get sound_rain;

  /// No description provided for @sound_waves.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get sound_waves;

  /// No description provided for @sound_forest.
  ///
  /// In en, this message translates to:
  /// **'Forest Breeze'**
  String get sound_forest;

  /// No description provided for @sound_campfire.
  ///
  /// In en, this message translates to:
  /// **'Campfire'**
  String get sound_campfire;

  /// No description provided for @timer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timer;

  /// No description provided for @fadeOut.
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeOut;

  /// No description provided for @minutesLeft.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String minutesLeft(int minutes);

  /// No description provided for @soundsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} sound} other{{count} sounds}}'**
  String soundsCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
