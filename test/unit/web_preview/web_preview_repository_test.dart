import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cartridge/features/web_preview/data/web_preview_repository.dart';
import 'package:cartridge/features/web_preview/domain/web_preview.dart';

void main() {
  late Database db;
  late WebPreviewRepository repo;

  setUpAll(() {
    // FFI 초기화 (VM 환경 unit test용)
    sqfliteFfiInit();
  });

  setUp(() async {
    db = await _openInMemoryDb();
    repo = WebPreviewRepository(db: () async => db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WebPreviewRepository', () {
    test('find(): 없으면 null, upsert() 후에는 값 반환', () async {
      final miss = await repo.find('https://x.test');
      expect(miss, isNull);

      final now = DateTime.now();
      final p = WebPreview(
        url: 'https://x.test',
        title: 'X',
        imagePath: '/tmp/x.png',
        imageUrl: 'https://img/x.png',
        mime: 'image/png',
        etag: 'W/"abc"',
        lastModified: 'Tue, 01 Jan 2030 00:00:00 GMT',
        statusCode: 200,
        fetchedAt: now,
        expiresAt: now.add(const Duration(days: 1)),
        hash: 'deadbeef',
      );
      await repo.upsert(p);

      final hit = await repo.find('https://x.test');
      expect(hit, isNotNull);
      expect(hit!.url, 'https://x.test');
      expect(hit.title, 'X');
      expect(hit.imagePath, '/tmp/x.png');
      expect(hit.imageUrl, 'https://img/x.png');
      expect(hit.mime, 'image/png');
      expect(hit.etag, 'W/"abc"');
      expect(hit.statusCode, 200);
      expect(hit.fetchedAt.millisecondsSinceEpoch, p.fetchedAt.millisecondsSinceEpoch);
      expect(hit.expiresAt!.millisecondsSinceEpoch, p.expiresAt!.millisecondsSinceEpoch);
      expect(hit.hash, 'deadbeef');
    });

    test('changes 스트림: upsert(url) 호출마다 url emit', () async {
      final urls = <String>[];
      final sub = repo.changes.listen(urls.add);

      await repo.upsert(_mk('https://a.test'));
      await repo.upsert(_mk('https://b.test'));

      // 마이크로태스크 큐 비우기
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(urls, ['https://a.test', 'https://b.test']);
    });

    test('link()/allUrlsFor()/unlink()', () async {
      // FK 제약 때문에 링크 전에 preview 존재해야 함
      await repo.upsert(_mk('https://a.test'));
      await repo.upsert(_mk('https://b.test'));

      await repo.link('post', '1', 'https://a.test');
      await repo.link('post', '2', 'https://b.test');

      final urls = await repo.allUrlsFor('post');
      expect(urls.toSet(), {'https://a.test', 'https://b.test'});

      await repo.unlink('post', '1');
      final urls2 = await repo.allUrlsFor('post');
      expect(urls2.toSet(), {'https://b.test'});
    });

    test('allImagePaths(): NULL 제외하고 Set 반환', () async {
      await repo.upsert(_mk('https://a.test', imagePath: '/p/a.png'));
      await repo.upsert(_mk('https://b.test')); // null
      await repo.upsert(_mk('https://c.test', imagePath: '/p/c.jpg'));

      final set = await repo.allImagePaths();
      expect(set, {'/p/a.png', '/p/c.jpg'});
    });

    test('sweepOrphans(): web_links에 참조 없는 preview 삭제', () async {
      await repo.upsert(_mk('https://keep.test'));
      await repo.upsert(_mk('https://drop.test'));

      // keep만 연결
      await repo.link('post', '1', 'https://keep.test');

      final n = await repo.sweepOrphans();
      expect(n, 1);

      final keep = await repo.find('https://keep.test');
      final drop = await repo.find('https://drop.test');
      expect(keep, isNotNull);
      expect(drop, isNull);
    });

    test('deleteExpired(): expires_at 이전 항목만 삭제', () async {
      final now = DateTime.now();
      await repo.upsert(_mk('https://old.test', expiresAt: now.subtract(const Duration(hours: 1))));
      await repo.upsert(_mk('https://new.test', expiresAt: now.add(const Duration(hours: 1))));
      await repo.upsert(_mk('https://noexp.test', expiresAt: null));

      final n = await repo.deleteExpired();
      expect(n, 1);

      final old = await repo.find('https://old.test');
      final neww = await repo.find('https://new.test');
      final noexp = await repo.find('https://noexp.test');

      expect(old, isNull);
      expect(neww, isNotNull);
      expect(noexp, isNotNull);
    });
  });
}

/// 인메모리 SQLite(DB 스키마 생성 포함)
Future<Database> _openInMemoryDb() async {
  final db = await databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await db.execute('PRAGMA busy_timeout = 5000;');
        await db.execute('PRAGMA journal_mode = WAL;');
      },
      onCreate: (db, version) async {
        final b = db.batch();
        b.execute('''
        CREATE TABLE web_previews (
          url            TEXT PRIMARY KEY,
          title          TEXT NOT NULL DEFAULT '',
          image_path     TEXT NULL,
          image_url      TEXT NULL,
          mime           TEXT NULL,
          etag           TEXT NULL,
          last_modified  TEXT NULL,
          status_code    INTEGER NULL,
          fetched_at_ms  INTEGER NOT NULL,
          expires_at_ms  INTEGER NULL,
          hash           TEXT NULL
        );
      ''');

        b.execute('''
        CREATE TABLE web_links (
          source        TEXT NOT NULL,
          source_id     TEXT NOT NULL,
          url           TEXT NOT NULL,
          created_at_ms INTEGER NOT NULL,
          PRIMARY KEY (source, source_id),
          FOREIGN KEY (url) REFERENCES web_previews(url) ON DELETE CASCADE
        );
      ''');

        b.execute('CREATE INDEX idx_links_source ON web_links(source);');
        b.execute('CREATE INDEX idx_links_url    ON web_links(url);');
        await b.commit(noResult: true);
      },
    ),
  );
  return db;
}

WebPreview _mk(
    String url, {
      String title = 'title',
      String? imagePath,
      String? imageUrl = 'https://img/x.png',
      String? mime = 'image/png',
      String? etag = 'W/"etag"',
      String? lastModified = 'Wed, 01 Jan 2030 00:00:00 GMT',
      int? statusCode = 200,
      DateTime? fetchedAt,
      DateTime? expiresAt,
      String? hash = 'hash',
    }) {
  return WebPreview(
    url: url,
    title: title,
    imagePath: imagePath,
    imageUrl: imageUrl,
    mime: mime,
    etag: etag,
    lastModified: lastModified,
    statusCode: statusCode,
    fetchedAt: fetchedAt ?? DateTime.now(),
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 1)),
    hash: hash,
  );
}
