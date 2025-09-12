// test/features/content/content_index_test.dart
import 'dart:convert';

import 'package:cartridge/features/cartridge/content/content.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper: rootBundle 자산을 메모리로 모킹
Future<void> _mockAssets(Map<String, String> assets) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (ByteData? message) async {
    final key = utf8.decode(
      message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes),
    );
    if (!assets.containsKey(key)) return null; // not found → FlutterError throw
    final bytes = Uint8List.fromList(utf8.encode(assets[key]!));
    final buffer = bytes.buffer;
    return ByteData.view(buffer);
  });
}

Future<void> _clearAssetCache() async {
  final bundle = rootBundle;
  try { (bundle as dynamic).clear(); } catch (_) {/* no-op for non-caching impl */}
}

void main() {
  group('ContentIndex / ContentEntry', () {
    test('index.yaml은 YAML list여야 한다 (형식 오류)', () async {
      await _mockAssets({
        'assets/content/index.yaml': '''
id: x
title: { ko: 타이틀 }
''',
      });
      expect(
            () => loadContentIndex(),
        throwsA(isA<FormatException>()), // "index.yaml must be a YAML list"
      );
    });

    test('type=detail 에서 markdown 누락 시 예외', () async {
      await _mockAssets({
        'assets/content/index.yaml': '''
- id: battle
  category: hyZone
  type: detail
  title: { ko: 대결모드 }
''',
      });
      expect(() => loadContentIndex(), throwsA(isA<FormatException>()));
    });

    test('type=link 에서 url 누락 시 예외', () async {
      await _mockAssets({
        'assets/content/index.yaml': '''
- id: info
  category: info
  type: link
  title: { ko: 링크 }
''',
      });
      expect(() => loadContentIndex(), throwsA(isA<FormatException>()));
    });

    test('URL 와일드카드(*) / 언어별 URL 선택', () async {
      const path = 'assets/content/index_url.yaml';
      await _mockAssets({
        path: '''
- id: a
  category: info
  type: link
  title: { ko: A, en: A }
  url: { "*": "https://all.example" }

- id: b
  category: info
  type: link
  title: { ko: B, en: B }
  url: { ko: "https://ko.example", en: "https://en.example" }
''',
      });
      await _clearAssetCache();
      final idx = await loadContentIndex(assetPath: path);
      final a = idx.entries.firstWhere((e) => e.id == 'a');
      final b = idx.entries.firstWhere((e) => e.id == 'b');

      expect(a.urlFor('ko'), 'https://all.example');
      expect(a.urlFor('en'), 'https://all.example');
      expect(b.urlFor('ko'), 'https://ko.example');
      expect(b.urlFor('en'), 'https://en.example');
    });

    test('title/description 언어 Fallback (ko → en → first)', () async {
      const path = 'assets/content/index_fallback.yaml';
      await _mockAssets({
        path: '''
- id: only-ko
  category: info
  type: detail
  title: { ko: 한글제목 }
  description: { ko: 한글설명 }
  markdown: assets/content/only-ko.md
''',
        'assets/content/only-ko.md': '# dummy',
      });

      await _clearAssetCache();
      final idx = await loadContentIndex(assetPath: path);
      final e = idx.entries.single;
      expect(e.titleFor('en'), '한글제목');
      expect(e.descriptionFor('en'), '한글설명');
    });

    test('filter는 카테고리/쿼리/언어를 인지하여 목록을 거른다', () async {
      const path = 'assets/content/index_filter.yaml';
      await _mockAssets({
        path: '''
- id: a
  category: hyZone
  type: detail
  title: { ko: 대결모드, en: Battle Mode }
  description: { ko: 대결 설명, en: Battle desc }
  markdown: assets/content/b.md
- id: b
  category: info
  type: link
  title: { ko: 정보, en: Info }
  description: { ko: 아이템, en: Items }
  url: https://example.com
''',
        'assets/content/b.md': '# b',
      });

      await _clearAssetCache();
      final idx = await loadContentIndex(assetPath: path);
      // en에서 "Battle"로 검색 → a만
      final enOnly = idx.filter(category: null, query: 'Battle', lang: 'en');
      expect(enOnly.map((e) => e.id), ['a']);

      // 카테고리 info만
      final infoOnly = idx.filter(category: ContentCategory.info, query: '', lang: 'ko');
      expect(infoOnly.map((e) => e.id), ['b']);
    });
  });
}
