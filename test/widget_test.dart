import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sleepy/main.dart';

void main() {
  testWidgets('Sleepy smoke test: renders home title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('Sleepy Audio'), findsOneWidget);
  });
}
