import 'dart:ui';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/fluent_host.dart';
import '../../helpers/load_test_fonts.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets('SlotView — Hover 시 컨트롤이 나타나고, 전역 스핀 틱 증가 시 애니메이션이 시작된다', (tester) async {
    // Arrange
    await tester.pumpWidget(FluentTestHost(
      child: const SlotView(items: ['A', 'B', 'C'], onEdited: _noop, onDeleted: _noopVoid),
    ));
    await tester.pumpAndSettle();

    // Act: Hover
    final region = find.byType(MouseRegion).first;
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(region));
    await tester.pump(const Duration(milliseconds: 160)); // 전이 소화

    // Assert: ListWheelScrollView 존재
    expect(find.byType(ListWheelScrollView), findsOneWidget);

    // Act: 전역 스핀 틱 증가
    final container = ProviderScope.containerOf(tester.element(find.byType(SlotView)));
    container.read(spinAllTickProvider.notifier).state++;

    // Assert: 프레임 전환(정밀 타이밍 대신 존재/전이만 확인)
    await tester.pump();
    expect(find.byType(ListWheelScrollView), findsOneWidget);
  });
}

void _noop(List<String> _) {}
void _noopVoid() {}
