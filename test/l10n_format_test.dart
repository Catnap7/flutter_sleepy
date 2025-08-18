import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sleepy/l10n/app_localizations_en.dart';
import 'package:flutter_sleepy/l10n/app_localizations_ko.dart';

void main() {
  test('minutesLeft formats correctly (EN/KO)', () {
    final en = AppLocalizationsEn();
    final ko = AppLocalizationsKo();

    expect(en.minutesLeft(5), '5 min left');
    expect(ko.minutesLeft(5), '5분 남음');
  });

  test('soundsCount pluralization (EN/KO)', () {
    final en = AppLocalizationsEn();
    final ko = AppLocalizationsKo();

    expect(en.soundsCount(1), '1 sound');
    expect(en.soundsCount(3), '3 sounds');

    expect(ko.soundsCount(1), '1개 사운드');
    expect(ko.soundsCount(3), '3개 사운드');
  });
}

