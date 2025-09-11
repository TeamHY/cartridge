import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/app/presentation/widgets/stage_shell.dart';
import 'package:cartridge/app/presentation/controllers/app_stage_provider.dart';
import 'package:cartridge/theme/theme.dart';

import '../helpers/fluent_host.dart';
import '../helpers/load_test_fonts.dart';

void main() {
  setUpAll(() async { await loadTestFonts(); });

  testWidgets('스플래시: 초기 배경은 초기 테마 색상과 동일하다 (AAA)', (tester) async {
    final darkResolved = AppTheme.resolve(AppThemeKey.dark);

    await tester.pumpWidget(
      FluentTestHost(
        themeKey: AppThemeKey.dark,
        overrides: [
          appStageProvider.overrideWithValue(AppStage.splash),
        ],
        child: const StageShell(),
      ),
    );
    await tester.pump();

    final container = tester.widget<Container>(find.byKey(const Key('splash-bg')));
    expect(container.color, equals(darkResolved.dark.scaffoldBackgroundColor));

    final vis = tester.widget<Visibility>(find.byKey(const Key('splash-spinner')));
    expect(vis.visible, isTrue);
  });

  testWidgets('스플래시: 전환 시작 시 스피너 숨김 (AAA)', (tester) async {

    // 1) 스플래시 유지
    await tester.pumpWidget(FluentTestHost(
      themeKey: AppThemeKey.light,
      overrides: [ appStageProvider.overrideWithValue(AppStage.splash) ],
      child: const StageShell(),
    ));
    await tester.pump();
    expect(
      tester.widget<Visibility>(find.byKey(const Key('splash-spinner'))).visible,
      isTrue,
    );

    // 2) 메인으로 전환 → StageShell 내부 애니메이션 시작
    await tester.pumpWidget(FluentTestHost(
      themeKey: AppThemeKey.light,
      overrides: [ appStageProvider.overrideWithValue(AppStage.main) ],
      child: const StageShell(),
    ));

    // 애니메이션 1프레임만 흘려도 컨트롤러 forward()가 시작됨
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      tester.widget<Visibility>(find.byKey(const Key('splash-spinner'))).visible,
      isFalse,
    );

    // 애니메이션 완료 후 스플래시는 제거됨
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.byKey(const Key('splash-spinner')), findsNothing);
  });

}
