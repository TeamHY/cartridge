import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/slot_machine/application/slot_machine_controller.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/slot_machine_service.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';
import 'package:cartridge/core/service_providers.dart'; // slotMachineServiceProvider

class _MockService extends Mock implements SlotMachineService {}

void main() {
  group('SlotMachineController — 상태 전이', () {
    late _MockService mock;

    setUp(() {
      mock = _MockService();
      registerFallbackValue(<String>[]);
    });

    test('build: 초기 로드에서 listAll의 결과로 AsyncData가 된다', () async {
      // Arrange
      when(() => mock.listAll()).thenAnswer((_) async => const [
        Slot(id: 'A', items: ['x']),
        Slot(id: 'B', items: ['y']),
      ]);
      final container = ProviderContainer(overrides: [
        slotMachineServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      // Act
      final result = await container.read(slotMachineControllerProvider.future);

      // Assert
      expect(result.map((e) => e.id), ['A', 'B']);
      final state = container.read(slotMachineControllerProvider);
      expect(state.hasValue, isTrue);
    });

    test('addLeft: 성공 시 최신 리스트로 AsyncData 갱신', () async {
      // Arrange
      when(() => mock.listAll()).thenAnswer((_) async => const []);
      when(() => mock.createLeft(defaultText: any(named: 'defaultText')))
          .thenAnswer((_) async => const [Slot(id: 'NEW', items: ['L'])]);

      final container = ProviderContainer(overrides: [
        slotMachineServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);
      await container.read(slotMachineControllerProvider.future);

      // Act
      await container.read(slotMachineControllerProvider.notifier).addLeft(defaultText: 'L');

      // Assert
      final s = container.read(slotMachineControllerProvider);
      expect(s.hasValue, isTrue);
      expect(s.requireValue.single.items, ['L']);
    });

    test('removeSlot: 서비스 예외는 AsyncError로 래핑된다', () async {
      // Arrange
      when(() => mock.listAll()).thenAnswer((_) async => const [Slot(id: 'A', items: ['x'])]);
      when(() => mock.delete(any())).thenThrow(Exception('boom'));

      final container = ProviderContainer(overrides: [
        slotMachineServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);
      await container.read(slotMachineControllerProvider.future);

      // Act
      await container.read(slotMachineControllerProvider.notifier).removeSlot('A');

      // Assert
      final s = container.read(slotMachineControllerProvider);
      expect(s.hasError, isTrue);
    });

    test('setSlotItems: 빈 배열이면 삭제 후 리스트를 수신한다', () async {
      // Arrange
      when(() => mock.listAll()).thenAnswer((_) async => const [Slot(id: 'A', items: ['x'])]);
      when(() => mock.setItems('A', const [])).thenAnswer((_) async => const []);

      final container = ProviderContainer(overrides: [
        slotMachineServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);
      await container.read(slotMachineControllerProvider.future);

      // Act
      await container.read(slotMachineControllerProvider.notifier).setSlotItems('A', const []);

      // Assert
      final s = container.read(slotMachineControllerProvider);
      expect(s.hasValue, isTrue);
      expect(s.requireValue, isEmpty);
    });

    test('아이템 CRUD(add/update/remove) 호출 시 최신 리스트로 갱신된다', () async {
      // Arrange
      when(() => mock.listAll()).thenAnswer((_) async => const [Slot(id: 'A', items: ['x'])]);
      when(() => mock.addItem('A', 'y')).thenAnswer((_) async => const [Slot(id: 'A', items: ['x', 'y'])]);
      when(() => mock.updateItem('A', 0, 'X')).thenAnswer((_) async => const [Slot(id: 'A', items: ['X', 'y'])]);
      when(() => mock.removeItem('A', 1)).thenAnswer((_) async => const [Slot(id: 'A', items: ['X'])]);

      final container = ProviderContainer(overrides: [
        slotMachineServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);
      await container.read(slotMachineControllerProvider.future);

      // Act & Assert
      await container.read(slotMachineControllerProvider.notifier).addItem('A', 'y');
      expect(container.read(slotMachineControllerProvider).requireValue.single.items, ['x', 'y']);

      await container.read(slotMachineControllerProvider.notifier).updateItem('A', 0, 'X');
      expect(container.read(slotMachineControllerProvider).requireValue.single.items, ['X', 'y']);

      await container.read(slotMachineControllerProvider.notifier).removeItem('A', 1);
      expect(container.read(slotMachineControllerProvider).requireValue.single.items, ['X']);
    });
  });
}
