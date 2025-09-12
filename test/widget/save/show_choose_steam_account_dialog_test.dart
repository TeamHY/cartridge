import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/features/isaac/save/presentation/widgets/show_choose_steam_account_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Doubles
// ─────────────────────────────────────────────────────────────────────────────
class _FakeProfile implements SteamAccountProfile {
  @override
  final String? personaName;
  @override
  final String savePath;
  @override
  final String? avatarPngPath;

  _FakeProfile(this.personaName)
      : savePath = 'C:/dummy',
        avatarPngPath = null;

  @override
  int get accountId => 0;
  @override
  bool get mostRecent => false;
  @override
  String get steamId64 => '0';
}

/// 하네스: 버튼으로 다이얼로그를 열고, 선택 결과를 Text로 노출
class _Harness extends StatefulWidget {
  final List<SteamAccountProfile> items;
  final Locale locale;

  const _Harness({
    required this.items,
    this.locale = const Locale('ko'),
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String _selectedLabel = '(none)';

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko')],
      locale: widget.locale,
      home: NavigationView(
        content: ScaffoldPage(
          content: Center(
            child: Builder(
              builder: (innerCtx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Button(
                    key: const Key('open_button'),
                    child: const Text('Open'),
                    onPressed: () async {
                      final res = await showChooseSteamAccountDialog(
                        innerCtx,
                        items: widget.items,
                      );
                      final l = AppLocalizations.of(innerCtx);
                      setState(() {
                        if (res == null) {
                          return;
                        }
                        final name = res.personaName?.trim();
                        _selectedLabel =
                        (name == null || name.isEmpty) ? l.common_unknown : name;
                      });
                    },
                  ),
                  Gaps.h8,
                  Text('selected: $_selectedLabel', key: const Key('selected_label')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


void main() {
  testWidgets('다이얼로그 오픈 시 제목과 항목들이 보인다 (AAA)', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    // Arrange
    final p1 = _FakeProfile('Alice');
    final p2 = _FakeProfile(''); // 빈 이름 -> "(이름 미설정)"로 표기됨
    await tester.pumpWidget(ProviderScope(child: _Harness(items: [p1, p2], locale: Locale('ko'))));

    // Act
    await tester.tap(find.byKey(const ValueKey('open_button')));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text(l.choose_steam_title), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text(l.common_unknown), findsOneWidget);
  });

  testWidgets('취소 시 null로 닫히고 라벨은 (none) 유지 (AAA)', (tester) async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    // Arrange
    final items = <SteamAccountProfile>[_FakeProfile('홍길동')];
    await tester.pumpWidget(ProviderScope(child: _Harness(items: items, locale: Locale('ko'))));

    final label = find.byKey(const ValueKey('selected_label'));
    expect(label, findsOneWidget);
    expect((tester.widget<Text>(label)).data, 'selected: (none)'); // 초기값 확인

    // Act: 열기 → 취소
    await tester.tap(find.byKey(const ValueKey('open_button')));
    await tester.pumpAndSettle();
    expect(find.text(l.choose_steam_title), findsOneWidget);

    await tester.tap(find.widgetWithText(Button, l.common_cancel));
    await tester.pumpAndSettle();

    // Assert: 여전히 (none)
    expect((tester.widget<Text>(label)).data, 'selected: (none)');
  });

  testWidgets('항목 선택 시 라벨이 선택한 이름으로 갱신 (AAA)', (tester) async {
    // Arrange
    final items = <SteamAccountProfile>[_FakeProfile('Alice'), _FakeProfile('')];
    await tester.pumpWidget(ProviderScope(child: _Harness(items: items)));

    // Act
    await tester.tap(find.byKey(const ValueKey('open_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    // Assert
    final label = find.byKey(const ValueKey('selected_label'));
    expect((tester.widget<Text>(label)).data, 'selected: Alice');
  });
}