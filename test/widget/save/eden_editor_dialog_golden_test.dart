import 'package:cartridge/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/isaac/runtime/domain/isaac_versions.dart';
import 'package:cartridge/features/isaac/save/domain/ports/eden_tokens_port.dart';
import 'package:cartridge/features/steam/domain/models/steam_account_profile.dart';
import 'package:cartridge/features/isaac/save/presentation/widgets/show_eden_editor_dialog.dart';

import '../../helpers/load_test_fonts.dart';

class MockSteamAccountProfile extends Mock implements SteamAccountProfile {}

class FakeEdenPort implements EdenTokensPort {
  @override
  Future<int> read(SteamAccountProfile acc, IsaacEdition e, int slot) async => 123;
  @override
  Future<void> write(
      SteamAccountProfile acc, IsaacEdition e, int slot, int value, {
        bool makeBackup = true, SaveWriteMode mode = SaveWriteMode.atomicRename,
      }) async {}
}

class _Host extends ConsumerWidget {
  const _Host({this.locale = const Locale('ko')});
  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FluentApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko')],
      locale: locale,
      theme: FluentThemeData(
        fontFamily: 'Pretendard',
      ),
      home: ScaffoldPage(
        content: Center(
          child: Builder(
            builder: (innerCtx) => Button(
              child: const Text('Open'),
              onPressed: () => openEdenTokenEditor(innerCtx, ref),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestFonts();
  });

  testGoldens('초기 오픈: 다이얼로그 골든이 매칭된다 (AAA)', (tester) async {
    // Arrange: 계정 1개, 에디션/슬롯 고정, 포트 페이크
    final acc = MockSteamAccountProfile();
    final l = await AppLocalizations.delegate.load(const Locale('ko'));

    final overrides = <Override>[
      steamAccountsProvider.overrideWith((ref) async => [acc]),
      editionAndSlotsProvider.overrideWithProvider(
        FutureProvider.family((ref, args) async => (edition: IsaacEdition.afterbirthPlus, slots: [1,2])),
      ),
      edenTokensPortProvider.overrideWithValue(FakeEdenPort()),
    ];

    await loadAppFonts();
    await tester.pumpWidgetBuilder(
      ProviderScope(overrides: overrides, child: const _Host(locale: Locale('ko'))),
      surfaceSize: const Size(800, 600),
    );

    // Act
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Assert (텍스트 존재 + Golden)
    expect(find.text(l.eden_title), findsOneWidget);
    await screenMatchesGolden(tester, 'eden_dialog_initial');
  });
}
