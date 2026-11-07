import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: buildAppTheme(brightness),
    home: Material(child: Center(child: child)),
  );
}

void main() {
  testWidgets('AppNumberField steps and clamps to max', (tester) async {
    int? value = 9;
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => SizedBox(
        width: 160,
        child: AppNumberField(
          value: value,
          min: 1,
          max: 10,
          onChanged: (next) => setState(() => value = next),
        ),
      ),
    )));

    final plus = find.byType(AppIconButton).last;
    await tester.tap(plus);
    await tester.pump();
    expect(value, 10);

    await tester.tap(plus);
    await tester.pump();
    expect(value, 10);
  });

  testWidgets('AppSelect opens menu and reports the picked value',
      (tester) async {
    String? value = 'ko';
    await tester.pumpWidget(_host(StatefulBuilder(
      builder: (context, setState) => AppSelect<String>(
        value: value,
        onChanged: (next) => setState(() => value = next),
        items: const [
          AppSelectItem(value: 'ko', child: Text('한국어')),
          AppSelectItem(value: 'en', child: Text('English')),
        ],
      ),
    )));

    await tester.tap(find.byType(AppSelect<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MenuItemButton, 'English'));
    await tester.pumpAndSettle();

    expect(value, 'en');
  });

  testWidgets('controls share the control height on Windows', (tester) async {
    await tester.pumpWidget(_host(SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppTextField(placeholder: 'a'),
          const AppTextField(placeholder: 'a', mono: true),
          AppButton(onPressed: () {}, child: const Text('a')),
          AppToggleButton(
              checked: true, onChanged: (_) {}, child: const Text('a')),
          AppSelect<int>(
            value: 1,
            onChanged: (_) {},
            items: const [AppSelectItem(value: 1, child: Text('a'))],
          ),
        ],
      ),
    )));

    for (final type in [
      AppTextField,
      AppButton,
      AppToggleButton,
      AppSelect<int>,
    ]) {
      for (final element in find.byType(type).evaluate()) {
        expect(tester.getSize(find.byWidget(element.widget)).height,
            appControlHeight,
            reason: '$type');
      }
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets('dark theme exposes dark tokens', (tester) async {
    late AppColors colors;
    await tester.pumpWidget(_host(
      Builder(builder: (context) {
        colors = AppColors.of(context);
        return const SizedBox();
      }),
      brightness: Brightness.dark,
    ));

    expect(colors, same(AppColors.dark));
  });
}
