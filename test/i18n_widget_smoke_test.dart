import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sleepy/l10n/app_localizations.dart';

Widget _buildApp({Locale? locale}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Text(AppLocalizations.of(context)!.howItWorks, textDirection: TextDirection.ltr),
    ),
  );
}

void main() {
  testWidgets('shows EN localized string', (tester) async {
    await tester.pumpWidget(_buildApp(locale: const Locale('en')));
    await tester.pump();
    expect(find.text('How It Works'), findsOneWidget);
  });

  testWidgets('shows KO localized string', (tester) async {
    await tester.pumpWidget(_buildApp(locale: const Locale('ko')));
    await tester.pump();
    expect(find.text('사용법 안내'), findsOneWidget);
  });
}

