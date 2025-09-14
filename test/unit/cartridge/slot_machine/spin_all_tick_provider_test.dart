import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';

void main() {
  test('spinAllTickProvider 값을 증가시키면 구독자가 최신 값을 읽는다 (브로드캐스트)', () {
    // Arrange
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final initial = container.read(spinAllTickProvider);

    // Act
    container.read(spinAllTickProvider.notifier).state++;

    // Assert
    expect(container.read(spinAllTickProvider), initial + 1);
  });
}
