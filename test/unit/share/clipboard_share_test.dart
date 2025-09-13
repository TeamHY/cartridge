// test/share/clipboard_share_test.dart
import 'package:cartridge/core/utils/clipboard_share.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartridge/features/steam/domain/steam_app_urls.dart';

class _PlatformClipboardSpy {
  Map<String, dynamic>? lastArgs;
  int callCount = 0;

  void install() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      SystemChannels.platform,
          (MethodCall call) async {
        if (call.method == 'Clipboard.setData') {
          callCount++;
          lastArgs = Map<String, dynamic>.from(
              (call.arguments as Map).map((k, v) => MapEntry('$k', v)));
        }
        return null;
      },
    );
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  }

  String? get writtenText => lastArgs?['text'] as String?;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClipboardShare', () {
    final spy = _PlatformClipboardSpy();

    setUp(() {
      spy.install();
    });

    tearDown(() {
      spy.uninstall();
    });

    test('copyNamesPlain: 빈/공백 이름은 제외하고 줄바꿈으로 연결한다', () async {
      final items = [
        const ShareItem(name: 'Mod A', workshopId: '123'),
        const ShareItem(name: '   '), // 제외
        const ShareItem(name: 'Mod B'),
      ];

      await ClipboardShare.copyNamesPlain(items);

      expect(spy.callCount, 1);
      expect(spy.writtenText, 'Mod A\nMod B');
    });

    test('copyNamesMarkdown(asList: true): workshopId 있으면 링크, 없으면 텍스트', () async {
      // mdEsc와 동일 규칙(Regex)로 기대 문자열 구성
      String mdEsc(String s) =>
          s.replaceAllMapped(RegExp(r'([\\`*_{}\[\]()+\-!.#|>])'),
                  (m) => '\\${m[1]}');

      final items = [
        const ShareItem(name: 'Sword [Alpha]', workshopId: '111'),
        const ShareItem(name: 'Shield (Beta) + | > # ! . -'),
      ];

      await ClipboardShare.copyNamesMarkdown(items, asList: true);

      final expected1 =
          '- [${mdEsc('Sword [Alpha]')}](${SteamUrls.workshopItem('111')})';
      final expected2 = '- ${mdEsc('Shield (Beta) + | > # ! . -')}';

      expect(spy.writtenText, '$expected1\n$expected2');
    });

    test('copyNamesMarkdown(asList: false): 글머리표 없이 생성된다', () async {
      final items = [
        const ShareItem(name: 'No bullets', workshopId: '222'),
      ];

      await ClipboardShare.copyNamesMarkdown(items, asList: false);

      expect(
        spy.writtenText,
        '[No bullets](${SteamUrls.workshopItem('222')})',
      );
    });

    test('copyNamesRich: super_clipboard 미지원 시 Plain으로 폴백한다', () async {
      // 테스트 환경에선 SystemClipboard.instance == null 인 경우가 일반적 → 폴백 경로
      final items = [
        const ShareItem(name: 'Alpha', workshopId: '333'),
        const ShareItem(name: 'Beta'),
      ];

      await ClipboardShare.copyNamesRich(items);

      expect(spy.writtenText, 'Alpha\nBeta');
    });
  });
}
