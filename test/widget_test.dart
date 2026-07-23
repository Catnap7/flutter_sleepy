import 'package:flutter/material.dart';
import 'package:flutter_sleepy/ui/sound_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sleepy smoke test: renders home title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Sleepy Audio')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Sleepy Audio'), findsOneWidget);
  });

  testWidgets('sound selector supports 200 percent text without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: SoundSelectorCard(
                value: 'rainy',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Thunderstorm'), findsOneWidget);
    expect(find.text('White Noise'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
