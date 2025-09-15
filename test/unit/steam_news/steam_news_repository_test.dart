import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:cartridge/core/infra/file_io.dart' as fio;
import 'package:cartridge/features/steam_news/steam_news.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

SteamNewsItem _item({
  required String title,
  required String url,
  String contents = '',
  int? epochSec,
}) {
  return SteamNewsItem(
    title: title,
    url: url,
    contents: contents,
    epochSec: epochSec,
  );
}

Future<File> _stateFileInTmp(Directory tmp) async {
  final dir = await fio.ensureAppSupportSubDir('cache');
  return File(p.join(dir.path, 'news.json'));
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late Directory tmpDir;
  late SteamNewsRepository repo;

  setUp(() async {
    tmpDir = await Directory.systemTemp.createTemp('steam_news_test_');
    fio.setAppSupportDirProvider(() async => tmpDir);
    repo = SteamNewsRepository();
  });

  tearDown(() async {
    if (await tmpDir.exists()) {
      await tmpDir.delete(recursive: true);
    }
  });

  test('load(): 파일 없으면 기본값(lastFetch=null, items=[])', () async {
    final st = await repo.load();
    expect(st.lastFetch, isNull);
    expect(st.items, isEmpty);
  });

  test('save(): 파일 생성 + changes 이벤트 + load()로 동일 상태 복원', () async {
    final events = <void>[];
    final sub = repo.changes.listen(events.add);

    final now = DateTime.now().toUtc();
    final state = SteamNewsState(
      lastFetch: now,
      items: <SteamNewsItem>[
        _item(title: 't1', url: 'https://ex/1', contents: 'c1', epochSec: 100),
        _item(title: 't2', url: 'https://ex/2', contents: 'c2', epochSec: 200),
      ],
    );

    await repo.save(state);

    final file = await _stateFileInTmp(tmpDir);
    expect(await file.exists(), isTrue);

    await pumpEventQueue();
    expect(events.isNotEmpty, isTrue);

    final loaded = await repo.load();
    expect(loaded.items.length, 2);
    expect(loaded.items.first.title, 't1');
    expect(loaded.items.first.url, 'https://ex/1');
    expect(loaded.items.first.contents, 'c1');
    expect(loaded.items.first.epochSec, 100);
    // epochSec → date 변환도 동작
    expect(
      loaded.items.first.date,
      DateTime.fromMillisecondsSinceEpoch(100 * 1000),
    );

    expect(loaded.lastFetch?.toIso8601String(), now.toIso8601String());
    await sub.cancel();
  });

  test('save(): SteamNewsDefaults.count 상한으로 items 컷팅', () async {
    final cap = SteamNewsDefaults.count;
    final total = cap + 10;

    final items = <SteamNewsItem>[
      for (int i = 0; i < total; i++)
        _item(
          title: 'title-$i',
          url: 'https://ex/$i',
          contents: 'c$i',
          epochSec: i, // 증가
        ),
    ];

    final state = SteamNewsState(
      lastFetch: DateTime.utc(2020, 1, 1),
      items: items,
    );
    await repo.save(state);

    final file = await _stateFileInTmp(tmpDir);
    final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final savedItems = (raw['items'] as List?) ?? const [];
    expect(savedItems.length, cap, reason: '저장 시 상한으로 잘 잘라야 함');

    final loaded = await repo.load();
    expect(loaded.items.length, cap);
    // 순서 보존(앞에서부터 cap개)
    expect(loaded.items.first.title, 'title-0');
    expect(loaded.items.last.title, 'title-${cap - 1}');
  });

  test('load(): JSON 깨졌을 때도 예외 없이 기본값 반환', () async {
    final file = await _stateFileInTmp(tmpDir);
    await file.create(recursive: true);
    await file.writeAsString('{"lastFetch": "not-a-date", "items": BROKEN_JSON]');

    final st = await repo.load();
    expect(st.lastFetch, isNull);
    expect(st.items, isEmpty);
  });
}
