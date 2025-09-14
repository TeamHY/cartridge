import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/application/eden_editor_controller.dart';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';

class MockSteamAccountProfile extends Mock implements SteamAccountProfile {}

class FakeEdenPort implements EdenTokensPort {
  final Map<int, int> map;
  FakeEdenPort({Map<int, int>? initial}) : map = {...(initial ?? {})};

  @override
  Future<int> read(SteamAccountProfile acc, IsaacEdition e, int slot) async => map[slot] ?? 0;

  @override
  Future<void> write(
      SteamAccountProfile acc,
      IsaacEdition e,
      int slot,
      int value, {
        bool makeBackup = true,
        SaveWriteMode mode = SaveWriteMode.atomicRename,
      }) async {
    map[slot] = value;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(MockSteamAccountProfile());
  });

  test('초기 로드: 첫 슬롯의 값이 상태에 반영된다 (AAA)', () async {
    // Arrange
    final acc = MockSteamAccountProfile();
    final container = ProviderContainer(overrides: [
      edenTokensPortProvider.overrideWithValue(FakeEdenPort(initial: {1: 5, 2: 1})),
    ]);
    addTearDown(container.dispose);

    final args = EdenEditorArgs(
      account: acc,
      edition: IsaacEdition.afterbirthPlus,
      slots: const [1, 2],
      initialSlot: 1,
    );

    // Act
    final state = await container.read(edenEditorControllerProvider(args).future);

    // Assert
    expect(state.selectedSlot, 1);
    expect(state.currentValue, 5);
  });

  test('슬롯 전환: 선택 슬롯과 현재 값이 갱신된다 (AAA)', () async {
    final acc = MockSteamAccountProfile();
    final container = ProviderContainer(overrides: [
      edenTokensPortProvider.overrideWithValue(FakeEdenPort(initial: {1: 5, 2: 1})),
    ]);
    addTearDown(container.dispose);

    final args = EdenEditorArgs(
      account: acc,
      edition: IsaacEdition.repentance,
      slots: const [1, 2],
      initialSlot: 1,
    );

    await container.read(edenEditorControllerProvider(args).future);
    await container.read(edenEditorControllerProvider(args).notifier).selectSlot(2);

    final s = container.read(edenEditorControllerProvider(args)).value!;
    expect(s.selectedSlot, 2);
    expect(s.currentValue, 1);
  });

  test('저장 성공: 저장 후 재읽기로 상태가 갱신된다 (AAA)', () async {
    final acc = MockSteamAccountProfile();
    final container = ProviderContainer(overrides: [
      edenTokensPortProvider.overrideWithValue(FakeEdenPort(initial: {1: 10})),
    ]);
    addTearDown(container.dispose);

    final args = EdenEditorArgs(
      account: acc,
      edition: IsaacEdition.afterbirth,
      slots: const [1],
      initialSlot: 1,
    );

    await container.read(edenEditorControllerProvider(args).future);
    await container.read(edenEditorControllerProvider(args).notifier).save(777);

    final s = container.read(edenEditorControllerProvider(args)).value!;
    expect(s.currentValue, 777);
  });
}
