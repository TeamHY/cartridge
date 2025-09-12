import 'dart:convert';

import 'package:cartridge/features/cartridge/content/content.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> _mockAssets(Map<String, String> assets) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMessageHandler('flutter/assets', (ByteData? message) async {
    final key = utf8.decode(
      message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    if (key == 'AssetManifest.json') {
      final bytes = Uint8List.fromList(utf8.encode('{}'));
      return ByteData.view(bytes.buffer);
    }
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage(<String, Object?>{});
    }
    // 일반 에셋
    if (!assets.containsKey(key)) return null;
    final bytes = Uint8List.fromList(utf8.encode(assets[key]!));
    return ByteData.view(bytes.buffer);
  });
}

/// 간단 Fluent/Provider 래퍼
Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    child: FluentApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FluentLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: NavigationView(content: child),
    ),
  );
}

void main() {
  testWidgets('언어 블록이 있으면 해당 언어만 렌더', (tester) async {
    await _mockAssets({
      'assets/content/detail.md': '''
<!-- lang:ko -->
# 한글 제목
본문 KO
<!-- /lang -->

<!-- lang:en -->
# Title (English)
Body EN
<!-- /lang -->
''',
    });

    await tester.pumpWidget(_wrap(
      LocalizedMarkdownPage(
        title: 'Battle Mode',
        markdownAsset: 'assets/content/detail.md',
        onClose: () {},
      ),
      locale: const Locale('en'),
    ));

    // 로딩 → 렌더
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Title (English)'), findsOneWidget);
    expect(find.textContaining('Body EN'), findsOneWidget);
    expect(find.textContaining('한글 제목'), findsNothing);
  });

  testWidgets('언어 블록이 없으면 전체 파일 렌더 (안전망)', (tester) async {
    await _mockAssets({
      'assets/content/plain.md': '# Whole Document\nNo language blocks.',
    });

    await tester.pumpWidget(_wrap(
      LocalizedMarkdownPage(
        title: 'Plain',
        markdownAsset: 'assets/content/plain.md',
        onClose: () {},
      ),
      locale: const Locale('ko'),
    ));

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('Whole Document'), findsOneWidget);
    expect(find.textContaining('No language blocks.'), findsOneWidget);
  });

  testWidgets('로딩 실패 시 사용자 친화 문구 출력', (tester) async {
    // 의도적으로 자산 미등록 → loadString 실패
    await _mockAssets({});

    await tester.pumpWidget(_wrap(
      LocalizedMarkdownPage(
        title: 'Broken',
        markdownAsset: 'assets/content/missing.md',
        onClose: () {},
      ),
      locale: const Locale('ko'),
    ));

    await tester.pump(const Duration(milliseconds: 50));
    // 에러 문구(에러 코드는 숨김)
    expect(find.textContaining('문서를 불러오지 못했어요'), findsWidgets);
  });
}
