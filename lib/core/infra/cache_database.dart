import 'package:sqflite/sqlite_api.dart';
import 'package:cartridge/core/infra/sqlite_database.dart';

const kCacheDbFile = 'cartridge_cache.sqlite';
const kCacheDbVersion = 1;

Future<Database> cacheDatabase() {
  return openAppDatabase(
    kCacheDbFile,
    version: kCacheDbVersion,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON;');
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
  );
}
