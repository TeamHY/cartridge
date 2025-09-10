import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fluent_host.dart';
import '../../helpers/load_test_fonts.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets('SlotMachinePage — 다크 테마에서 기본 페이지가 정상 렌더링된다 (스모크)', (tester) async {
    // Arrange & Act
    await tester.pumpWidget(FluentTestHost(
      themeKey: AppThemeKey.dark,
      child: const SlotMachinePage(),
    ));
    await tester.pump();

    final page = find.byType(SlotMachinePage);
    expect(page, findsOneWidget);
    // Assert
    expect(
      find.descendant(of: page, matching: find.byType(ScaffoldPage)),
      findsOneWidget,
    );
  });
}
