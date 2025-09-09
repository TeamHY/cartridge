import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:cartridge/features/isaac/save/presentation/widgets/show_eden_editor_dialog.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class MockSteamAccountProfile extends Mock implements SteamAccountProfile {}

class FakeEdenPort implements EdenTokensPort {
  int value = 10;
  @override
  Future<int> read(SteamAccountProfile acc, IsaacEdition e, int slot) async => value;
  @override
  Future<void> write(
      SteamAccountProfile acc,
      IsaacEdition e,
      int slot,
      int newValue, {
        bool makeBackup = true,
        SaveWriteMode mode = SaveWriteMode.atomicRename,
      }) async {
    value = newValue;
  }
}

class _Host extends ConsumerWidget {
  const _Host();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      localizationsDelegates: const [FluentLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: NavigationView(
        content: ScaffoldPage(
          content: Center(
            child: Builder(
              builder: (innerCtx) => Button(
                child: const Text('Open'),
                onPressed: () => openEdenTokenEditor(innerCtx, ref),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('저장되면 플로우 성공 (UI 피드백 미검증, 효과만 검증)', (tester) async {
    // Arrange
    final acc = MockSteamAccountProfile();
    final fakePort = FakeEdenPort();

    final overrides = <Override>[
      steamAccountsProvider.overrideWith((ref) async => [acc]),
      editionAndSlotsProvider.overrideWithProvider(
        FutureProvider.family((ref, args) async =>
        (edition: IsaacEdition.repentance, slots: [1])),
      ),
      edenTokensPortProvider.overrideWithValue(fakePort),
    ];

    await tester.pumpWidget(
      ProviderScope(overrides: overrides, child: const _Host()),
    );

    // 다이얼로그 오픈
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('에덴 토큰'), findsOneWidget);

    // Act: 값 최대 → 저장
    await tester.tap(find.text('최대(10,000)'));
    await tester.pump(); // 값 반영
    await tester.tap(find.text('저장'));

    // 저장 비동기 처리 + 상태 갱신 한 프레임 확보
    await tester.pump();                         // onPressed 반환
    await tester.pump(const Duration(milliseconds: 50)); // state 반영

    // Assert: 포트에 실제 저장되었는지(효과)만 검증
    expect(fakePort.value, 10000);

    // (주의) InfoBar 내부 타이머 소진해서 pending timer 방지
    await tester.pump(const Duration(seconds: 4));
  });
}
