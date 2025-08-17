import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sleepy/theme/theme_controller.dart';

import 'package:flutter_sleepy/main.dart';

void main() {
  testWidgets('Sleepy smoke test: renders home title', (WidgetTester tester) async {
    final controller = ThemeController();
    await controller.load();
    await tester.pumpWidget(MyApp(controller: controller));
    await tester.pump();
    expect(find.text('Sleepy Audio'), findsOneWidget);
  });
}
