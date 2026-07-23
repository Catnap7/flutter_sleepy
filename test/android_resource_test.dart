import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('background notification uses an existing drawable icon', () {
    final serviceSource =
        File('lib/services/background_service.dart').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final icon = File(
      'android/app/src/main/res/drawable/ic_stat_sleepy.xml',
    );

    expect(serviceSource,
        contains("AndroidInitializationSettings('ic_stat_sleepy')"));
    expect(icon.existsSync(), isTrue);
    expect(icon.readAsStringSync(), contains('android:fillColor="#FFFFFFFF"'));
    expect(manifest, contains('@drawable/ic_stat_sleepy'));
    expect(
      manifest,
      contains('android.permission.POST_NOTIFICATIONS'),
    );
  });
}
