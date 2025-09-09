import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/features/isaac/save/presentation/widgets/show_eden_editor_dialog.dart';

class _FakeAcc implements SteamAccountProfile {
  @override
  String get savePath => r'C:\dummy';
  @override
  String? get personaName => 'Tester';
  @override
  int get accountId => throw UnimplementedError();
  @override
  String? get avatarPngPath => throw UnimplementedError();
  @override
  bool get mostRecent => throw UnimplementedError();
  @override
  String get steamId64 => throw UnimplementedError();
}

class _ThrowingEdenPort implements EdenTokensPort {
  @override
  Future<int> read(SteamAccountProfile a, IsaacEdition e, int s) async =>
      throw StateError('read failed');
  @override
  Future<void> write(SteamAccountProfile a, IsaacEdition e, int s, int v,
      {bool makeBackup = true, SaveWriteMode mode = SaveWriteMode.atomicRename}) async {}
}

class _Host extends ConsumerWidget {
  const _Host();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      localizationsDelegates: const [FluentLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
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
  testWidgets('읽기 실패 시 경고 InfoBar(안내)를 표시한다 (AAA)', (tester) async {
    final acc = _FakeAcc();
    final overrides = <Override>[
      steamAccountsProvider.overrideWith((ref) async => [acc]),
      editionAndSlotsProvider.overrideWithProvider(
        FutureProvider.family((ref, ({SteamAccountProfile acc, IsaacEdition? detected}) args) async =>
        (edition: IsaacEdition.repentance, slots: [1])),
      ),
      edenTokensPortProvider.overrideWithValue(_ThrowingEdenPort()),
    ];

    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const _Host()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // 경고 InfoBar 타이틀(‘안내’) 존재 확인
    expect(find.text('안내'), findsOneWidget);
  });

  testWidgets('Rebirth 에디션에서는 저장 버튼이 비활성화된다 (AAA)', (tester) async {
    final acc = _FakeAcc();
    final overrides = <Override>[
      steamAccountsProvider.overrideWith((ref) async => [acc]),
      editionAndSlotsProvider.overrideWithProvider(
        FutureProvider.family((ref, ({SteamAccountProfile acc, IsaacEdition? detected}) args) async =>
        (edition: IsaacEdition.rebirth, slots: [1])),
      ),
      edenTokensPortProvider.overrideWithValue(_ThrowingEdenPort()),
    ];

    await tester.pumpWidget(ProviderScope(overrides: overrides, child: const _Host()));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final saveBtnFinder = find.widgetWithText(FilledButton, '저장');
    final saveBtn = tester.widget<Button>(saveBtnFinder);
    expect(saveBtn.onPressed, isNull);
  });
}
