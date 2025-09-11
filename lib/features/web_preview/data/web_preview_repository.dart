import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:cartridge/core/infra/cache_database.dart';
import '../domain/web_preview.dart';

class WebPreviewRepository {
  final _changes = StreamController<String>.broadcast();
  Stream<String> get changes => _changes.stream;
  final Future<Database> Function() _db;
  WebPreviewRepository({Future<Database> Function()? db})
      : _db = db ?? cacheDatabase;

  Future<WebPreview?> find(String url) async {
    final db = await _db();
    final rows = await db.query('web_previews', where: 'url=?', whereArgs: [url], limit: 1);
    if (rows.isEmpty) return null;
    final m = rows.first;
    return WebPreview(
      url: m['url'] as String,
      title: (m['title'] as String?) ?? '',
      imagePath: m['image_path'] as String?,
      imageUrl: m['image_url'] as String?,
      mime: m['mime'] as String?,
      etag: m['etag'] as String?,
      lastModified: m['last_modified'] as String?,
      statusCode: m['status_code'] as int?,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(m['fetched_at_ms'] as int),
      expiresAt: (m['expires_at_ms'] is int) ? DateTime.fromMillisecondsSinceEpoch(m['expires_at_ms'] as int) : null,
      hash: m['hash'] as String?,
    );
  }

  Future<void> upsert(WebPreview p) async {
    final db = await _db();
    await db.insert('web_previews', {
      'url': p.url,
      'title': p.title,
      'image_path': p.imagePath,
      'image_url': p.imageUrl,
      'mime': p.mime,
      'etag': p.etag,
      'last_modified': p.lastModified,
      'status_code': p.statusCode,
      'fetched_at_ms': p.fetchedAt.millisecondsSinceEpoch,
      'expires_at_ms': p.expiresAt?.millisecondsSinceEpoch,
      'hash': p.hash,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _changes.add(p.url);
  }

  Future<void> link(String source, String sourceId, String url) async {
    final db = await _db();
    await db.insert('web_links', {
      'source': source,
      'source_id': sourceId,
      'url': url,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> unlink(String source, String sourceId) async {
    final db = await _db();
    await db.delete('web_links', where: 'source=? AND source_id=?', whereArgs: [source, sourceId]);
  }

  Future<List<String>> allUrlsFor(String source) async {
    final db = await _db();
    final rows = await db.query('web_links', columns: ['url'], where: 'source=?', whereArgs: [source]);
    return rows.map((e) => e['url'] as String).toList();
  }

  Future<Set<String>> allImagePaths() async {
    final db = await _db();
    final rows = await db.query('web_previews', columns: ['image_path']);
    return rows
        .map((e) => (e['image_path'] as String?))
        .whereType<String>()
        .toSet();
  }

  /// 참조 없는 preview 삭제
  Future<int> sweepOrphans() async {
    final db = await _db();
    return db.delete('web_previews',
        where: 'url NOT IN (SELECT url FROM web_links)');
  }

  /// 만료된 항목 삭제
  Future<int> deleteExpired() async {
    final db = await _db();
    return db.delete('web_previews',
        where: 'expires_at_ms IS NOT NULL AND expires_at_ms < ?',
        whereArgs: [DateTime.now().millisecondsSinceEpoch]);
  }

}
