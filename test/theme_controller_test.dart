import 'package:flutter/material.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('soundscape UI keeps a dark Material brightness', () {
    final controller = ThemeController();

    expect(controller.themeMode, ThemeMode.dark);
  });
}
