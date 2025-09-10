import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../helpers/fluent_host.dart';
import '../../helpers/load_test_fonts.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testGoldens('SlotView — Light/Dark 테마 시각 스냅샷이 일관되게 유지된다', (tester) async {
    // Arrange
    final light = FluentTestHost(
      themeKey: AppThemeKey.light,
      useNavigationView: false,
      wrapWithScaffoldPage: false,
      child: const SlotView(items: ['One', 'Two'], onEdited: _noop, onDeleted: _noopVoid),
    );
    final dark = FluentTestHost(
      themeKey: AppThemeKey.dark,
      useNavigationView: false,
      wrapWithScaffoldPage: false,
      child: const SlotView(items: ['One', 'Two'], onEdited: _noop, onDeleted: _noopVoid),
    );

    // Act
    final grid = GoldenBuilder.grid(
      columns: 2,
      widthToHeightRatio: 0.9,
    )
      ..addScenario('Light', light)
      ..addScenario('Dark', dark);


    await tester.pumpWidgetBuilder(grid.build(), surfaceSize: const Size(900, 700));

    // Assert
    await screenMatchesGolden(tester, 'slot_view_light_dark');
  });
}

void _noop(List<String> _) {}
void _noopVoid() {}
