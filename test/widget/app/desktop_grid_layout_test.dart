import 'package:cartridge/app/presentation/desktop_grid.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fluent_host.dart';
import '../../helpers/load_test_fonts.dart';

void main() {
  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets('DesktopGrid — full-row가 행을 분리하고, 나머지는 cols 개수로 포장된다', (tester) async {
    // Arrange
    final items = <GridItem>[
      GridItem(child: const SizedBox(width: 10, height: 10)),
      GridItem(child: const SizedBox(width: 10, height: 10)),
      const GridItem.full(child: SizedBox(width: 10, height: 10)),
      GridItem(child: const SizedBox(width: 10, height: 10)),
      GridItem(child: const SizedBox(width: 10, height: 10)),
    ];

    final width = AppBreakpoints.md + 100;

    await tester.pumpWidget(FluentTestHost(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: width),
          child: DesktopGrid(
            items: items,
            maxContentWidth: width,
            colsLg: 3,
            colsMd: 2,
            colsSm: 1,
          ),
        ),
      ),
    ));
    // NOTE: host 애니메이션에 막히지 않도록 settle 대신 한 프레임만
    await tester.pump();

    // Assert: DesktopGrid 내부(Row만) 세기 → 2개(앞/뒤 일반 행).
    final grid = find.byType(DesktopGrid);
    expect(find.descendant(of: grid, matching: find.byKey(const ValueKey('dg.row'))), findsNWidgets(2));
    expect(find.descendant(of: grid, matching: find.byKey(const ValueKey('dg.fullRow'))), findsOneWidget);
  });
}
