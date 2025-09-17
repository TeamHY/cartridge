import 'package:cartridge/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/isaac_save.dart';
import 'package:cartridge/features/steam/steam.dart';

class _FakeAcc implements SteamAccountProfile {
  @override
  String get savePath => r'C:\dummy';
  @override
  String? get personaName => 'Tester';
  @override
  int get accountId => 1234;
  @override
  String? get avatarPngPath => null;
  @override
  bool get mostRecent => true;
  @override
  String get steamId64 => "1234";
}


class _StubEdenPort implements EdenTokensPort {
  @override
  Future<int> read(SteamAccountProfile a, IsaacEdition e, int s) async => 42;
  @override
  Future<void> write(SteamAccountProfile a, IsaacEdition e, int s, int v,
      {bool makeBackup = true, SaveWriteMode mode = SaveWriteMode.atomicRename}) async {}
}

class _Host extends ConsumerWidget {
  const _Host({this.locale = const Locale('ko')});
  final Locale locale;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko')],
      locale: locale,
      home: ScaffoldPage(
        content: Center(
          child: Builder(
            builder: (innerCtx) => Button(
              child: const Text('Open'),
              onPressed: () => openEdenTokenEditor(innerCtx, ref),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Rebirth 에디션에서는 저장 버튼이 비활성화된다 (AAA)', (tester) async {
    final acc = _FakeAcc();
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    final overrides = <Override>[
      steamAccountsProvider.overrideWith((ref) async => [acc]),
      editionAndSlotsProvider.overrideWithProvider(
        FutureProvider.family((ref, ({SteamAccountProfile acc, IsaacEdition? detected}) args) async =>
        (edition: IsaacEdition.rebirth, slots: [1])),
      ),
      edenTokensPortProvider.overrideWithValue(_StubEdenPort()),
    ];

    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const _Host(locale: Locale('ko'))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final saveBtnFinder = find.widgetWithText(FilledButton, l.common_save);
    final saveBtn = tester.widget<Button>(saveBtnFinder);
    expect(saveBtn.onPressed, isNull);
  });
}
