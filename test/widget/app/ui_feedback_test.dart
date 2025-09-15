import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// 프로덕션 코드
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';

/// Overlay가 반드시 존재하도록, FluentApp 홈에 Overlay를 '명시'로 깐 테스트 호스트
class _Host extends StatelessWidget {
  final void Function(BuildContext) onPressed;
  const _Host({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      localizationsDelegates: const [FluentLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => NavigationView(
              content: ScaffoldPage(
                content: Center(
                  child: Builder(
                    builder: (ctx) => Button(
                      onPressed: () => onPressed(ctx),
                      child: const Text('TRIGGER'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _pumpAndTrigger(
    WidgetTester tester, {
      required void Function(BuildContext) call,
    }) async {
  await tester.pumpWidget(_Host(onPressed: call));
  await tester.tap(find.text('TRIGGER'));  // InfoBar 표시 트리거
  await tester.pump();                     // 스케줄링 반영
  await tester.pumpAndSettle();            // 애니메이션/마이크로태스크 정착
}

Future<void> _drainInfoBarTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets('UiFeedback.success: InfoBar가 뜨고 닫히면 사라진다', (tester) async {
    await _pumpAndTrigger(
      tester,
      call: (ctx) => UiFeedback.success(ctx, title: '저장 완료', content: '변경한 값이 적용되었어요.'),
    );

    final infoFinder = find.byType(InfoBar);
    expect(infoFinder, findsOneWidget);

    // 내용 검증
    expect(find.text('저장 완료'), findsOneWidget);
    expect(find.text('변경한 값이 적용되었어요.'), findsOneWidget);

    // severity 검증
    final info = tester.widget<InfoBar>(infoFinder);
    expect(info.severity, InfoBarSeverity.success);

    // 닫기(×) 버튼 눌러서 사라지는지 확인
    final closeBtn = find.descendant(of: infoFinder, matching: find.byType(IconButton));
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();
    expect(infoFinder, findsNothing);

    // 내부 타이머가 이미 예약돼 있을 수 있으니 drain
    await _drainInfoBarTimers(tester);
  });

  testWidgets('UiFeedback.error: 에러 InfoBar가 표시된다', (tester) async {
    await _pumpAndTrigger(
      tester,
      call: (ctx) => UiFeedback.error(ctx, title: '실패', content: '처리 중 오류가 발생했습니다.'),
    );

    final info = tester.widget<InfoBar>(find.byType(InfoBar));
    expect(info.severity, InfoBarSeverity.error);
    expect(find.text('실패'), findsOneWidget);
    expect(find.text('처리 중 오류가 발생했습니다.'), findsOneWidget);

    // 자동 닫힘 타이머 소진
    await _drainInfoBarTimers(tester);
  });

  testWidgets('UiFeedback.warn: 경고 InfoBar가 표시된다', (tester) async {
    await _pumpAndTrigger(
      tester,
      call: (ctx) => UiFeedback.warn(ctx, title: '주의', content: '조건을 확인하세요.'),
    );

    final info = tester.widget<InfoBar>(find.byType(InfoBar));
    expect(info.severity, InfoBarSeverity.warning);
    expect(find.text('주의'), findsOneWidget);
    expect(find.text('조건을 확인하세요.'), findsOneWidget);

    await _drainInfoBarTimers(tester);
  });

  testWidgets('UiFeedback.info: 정보 InfoBar가 표시된다', (tester) async {
    await _pumpAndTrigger(
      tester,
      call: (ctx) => UiFeedback.info(ctx, title: '안내', content: '처리가 시작되었습니다.'),
    );

    final info = tester.widget<InfoBar>(find.byType(InfoBar));
    expect(info.severity, InfoBarSeverity.info);
    expect(find.text('안내'), findsOneWidget);
    expect(find.text('처리가 시작되었습니다.'), findsOneWidget);

    await _drainInfoBarTimers(tester);
  });
}
