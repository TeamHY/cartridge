// test/widgets/ut_split_button_test.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cartridge/app/presentation/widgets/home/ut_split_button.dart';

void main() {
  Widget wrap(Widget child) {
    return FluentApp(
      home: NavigationView(
        content: ScaffoldPage(
          content: Center(
            child: SizedBox(width: 320, child: child), // 레이아웃 안정화
          ),
        ),
      ),
    );
  }

  testWidgets('main button fires onMainButtonPressed when enabled', (tester) async {
    var count = 0;
    final w = UtSplitButton.single(
      mainButtonText: 'Run',
      secondaryText: 'Now',
      buttonColor: Colors.blue,
      onPressed: () => count++,
      enabled: true,
    );

    await tester.pumpWidget(wrap(w));
    await tester.tap(find.text('Run')); // 좌측 메인 영역 탭
    await tester.pump();

    expect(count, 1);
  });

  testWidgets('tapping chevron opens flyout when items exist', (tester) async {
    final w = UtSplitButton(
      mainButtonText: 'Run',
      buttonColor: Colors.blue,
      onMainButtonPressed: () {},
      dropdownMenuItems: [
        MenuFlyoutItem(text: const Text('Option A'), onPressed: () {}),
      ],
      enabled: true,
      hasDropdown: true,
    );

    await tester.pumpWidget(wrap(w));
    await tester.tap(find.byIcon(FluentIcons.chevron_down)); // 우측 드롭다운
    await tester.pumpAndSettle();

    expect(find.text('Option A'), findsOneWidget);
  });

  testWidgets('disabled blocks both main press and flyout', (tester) async {
    var count = 0;
    final w = UtSplitButton(
      mainButtonText: 'Run',
      buttonColor: Colors.blue,
      onMainButtonPressed: () => count++,
      dropdownMenuItems: [
        MenuFlyoutItem(text: const Text('Option A'), onPressed: () {}),
      ],
      enabled: false,
      hasDropdown: true,
    );

    await tester.pumpWidget(wrap(w));
    await tester.tap(find.text('Run'));
    await tester.tap(find.byIcon(FluentIcons.chevron_down));
    await tester.pumpAndSettle();

    expect(count, 0);
    expect(find.text('Option A'), findsNothing);
  });
}
