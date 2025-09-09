import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cartridge/l10n/app_localizations.dart';

Future<AppLocalizations> pumpAndGetLocalization(
    WidgetTester tester,
    Locale locale,
    ) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: SizedBox()),
    ),
  );

  await tester.pump();

  final context = tester.element(find.byType(SizedBox));
  return AppLocalizations.of(context);
}

void main() {
  group('Localization Test', () {
    testWidgets('Korean locale - key: home_button_record', (tester) async {
      final loc = await pumpAndGetLocalization(tester, const Locale('ko'));
      expect(loc.home_button_record, '기록 모드');
    });

    testWidgets('English locale - key: home_button_record', (tester) async {
      final loc = await pumpAndGetLocalization(tester, const Locale('en'));
      expect(loc.home_button_record, 'Record\nMode');
    });

    testWidgets('Korean locale - key: slot_default', (tester) async {
      final loc = await pumpAndGetLocalization(tester, const Locale('ko'));
      expect(loc.slot_default, '기본');
    });

    testWidgets('English locale - key: slot_default', (tester) async {
      final loc = await pumpAndGetLocalization(tester, const Locale('en'));
      expect(loc.slot_default, 'Default');
    });
  });
}
