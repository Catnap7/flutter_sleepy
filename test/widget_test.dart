import 'package:flutter/material.dart';
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
}
