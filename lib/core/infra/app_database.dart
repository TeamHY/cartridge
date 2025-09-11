import 'dart:io' as io;

import 'package:sqflite/sqlite_api.dart';
import 'package:cartridge/core/infra/sqlite_database.dart';

const kAppDbFile = 'cartridge.sqlite';
const kAppDbVersion = 1;

/// Naming conventions
/// - Timestamps: *_at_ms (epoch millis)
/// - Booleans: INTEGER 0/1 (nullable only when tri-state is required)
/// - Position columns: pos (UI ordering)
Future<Database> appDatabase() {
  return openAppDatabase(
    kAppDbFile,
    version: kAppDbVersion,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON;');
    },
    onCreate: (db, version) async {
      final b = db.batch();

      // ───────────────────────────────────────────────────────────────────
      // Slot Machine
      // ───────────────────────────────────────────────────────────────────
      b.execute('''
        CREATE TABLE slots(
          id   TEXT PRIMARY KEY,
          pos  INTEGER NOT NULL
        );
      ''');
      b.execute('''
        CREATE TABLE slot_items(
          slot_id  TEXT    NOT NULL,
          position INTEGER NOT NULL,
          content  TEXT    NOT NULL,
          PRIMARY KEY (slot_id, position),
          FOREIGN KEY (slot_id) REFERENCES slots(id) ON DELETE CASCADE
        );
      ''');

      // ───────────────────────────────────────────────────────────────────
      // App Setting (single row: id=1)
      // ───────────────────────────────────────────────────────────────────
      b.execute('''
        CREATE TABLE app_setting(
          id INTEGER PRIMARY KEY CHECK(id = 1),
          isaac_path TEXT NOT NULL DEFAULT '',
          rerun_delay INTEGER NOT NULL DEFAULT 1000,
          language_code TEXT NOT NULL DEFAULT 'ko',
          theme_name TEXT NOT NULL DEFAULT 'system',
          options_ini_path TEXT NOT NULL DEFAULT '',
          use_auto_detect_install_path INTEGER NOT NULL DEFAULT 1,
          use_auto_detect_options_ini INTEGER NOT NULL DEFAULT 1
        );
      ''');

      // ───────────────────────────────────────────────────────────────────
      // Option Presets
      // ───────────────────────────────────────────────────────────────────
      b.execute('''
        CREATE TABLE option_presets(
          id               TEXT PRIMARY KEY,
          pos              INTEGER NOT NULL,
          name             TEXT    NOT NULL,
          use_repentogon   INTEGER NULL,      -- NULL/0/1
          options_json     TEXT    NOT NULL,  -- IsaacOptions JSON
          updated_at_ms    INTEGER NULL       -- epoch millis
        );
      ''');
      b.execute('CREATE INDEX idx_option_presets_pos ON option_presets(pos);');

      // ───────────────────────────────────────────────────────────────────
      // Mod Presets
      // ───────────────────────────────────────────────────────────────────
      b.execute('''
        CREATE TABLE mod_presets(
          id                TEXT PRIMARY KEY,
          pos               INTEGER NOT NULL,
          name              TEXT NOT NULL,
          sort_key          INTEGER NULL,
          ascending         INTEGER NULL,           -- 0/1 or NULL
          updated_at_ms     INTEGER NULL,           -- epoch millis
          last_sync_at_ms   INTEGER NULL,           -- epoch millis
          group_name        TEXT NULL,
          categories_json   TEXT NOT NULL DEFAULT '[]'
        );
      ''');
      b.execute('CREATE INDEX idx_mod_presets_pos ON mod_presets(pos);');

      b.execute('''
        CREATE TABLE mod_preset_entries(
          preset_id     TEXT NOT NULL,
          mod_key       TEXT NOT NULL,
          enabled       INTEGER NOT NULL DEFAULT 0, -- strictly binary
          favorite      INTEGER NOT NULL DEFAULT 0, -- 0/1
          updated_at_ms INTEGER NULL,               -- epoch millis
          PRIMARY KEY (preset_id, mod_key),
          FOREIGN KEY (preset_id) REFERENCES mod_presets(id) ON DELETE CASCADE
        );
      ''');
      b.execute('CREATE INDEX idx_mpe_preset ON mod_preset_entries(preset_id);');
      b.execute('CREATE INDEX idx_mpe_fav ON mod_preset_entries(preset_id, favorite);');

      // ───────────────────────────────────────────────────────────────────
      // Instances
      // ───────────────────────────────────────────────────────────────────
      b.execute('''
        CREATE TABLE instances (
          id               TEXT PRIMARY KEY,
          name             TEXT NOT NULL,
          option_preset_id TEXT NULL,
          game_mode        INTEGER NOT NULL DEFAULT 0,
          sort_key         INTEGER NULL,
          ascending        INTEGER NULL,           -- 0/1
          group_name       TEXT NULL,
          updated_at_ms    INTEGER NULL,           -- epoch millis
          last_sync_at_ms  INTEGER NULL,           -- epoch millis
          pos              INTEGER NOT NULL,       -- UI order

          -- image (optional)
          image_kind       INTEGER NULL,           -- 0:none, 1:sprite, 2:userfile
          image_index      INTEGER NULL,           -- sprite index
          image_path       TEXT NULL,              -- user file path
          image_fit        INTEGER NULL,           -- enum(BoxFit)

          FOREIGN KEY (option_preset_id)
            REFERENCES option_presets(id) ON DELETE SET NULL
        );
      ''');
      b.execute('CREATE INDEX idx_instances_pos    ON instances(pos);');
      b.execute('CREATE INDEX idx_instances_option ON instances(option_preset_id);');

      // instance ↔ mod presets (set semantics, orderless)
      b.execute('''
        CREATE TABLE instance_mod_presets (
          instance_id TEXT NOT NULL,
          preset_id   TEXT NOT NULL,
          PRIMARY KEY (instance_id, preset_id),
          FOREIGN KEY (instance_id) REFERENCES instances(id)   ON DELETE CASCADE,
          FOREIGN KEY (preset_id)   REFERENCES mod_presets(id) ON DELETE CASCADE
        );
      ''');
      b.execute('CREATE INDEX idx_imp_instance ON instance_mod_presets(instance_id);');
      b.execute('CREATE INDEX idx_imp_preset   ON instance_mod_presets(preset_id);');

      // instance overrides (tri-state enabled: NULL/0/1)
      b.execute('''
        CREATE TABLE instance_overrides (
          instance_id TEXT NOT NULL,
          mod_key     TEXT NOT NULL,
          enabled     INTEGER NULL,               -- NULL/0/1
          favorite    INTEGER NOT NULL DEFAULT 0, -- 0/1
          updated_at_ms  INTEGER NOT NULL,        -- epoch millis
          PRIMARY KEY (instance_id, mod_key),
          FOREIGN KEY (instance_id) REFERENCES instances(id) ON DELETE CASCADE
        );
      ''');

      // instance categories (optional)
      b.execute('''
        CREATE TABLE instance_categories (
          instance_id TEXT NOT NULL,
          category    TEXT NOT NULL,
          PRIMARY KEY (instance_id, category),
          FOREIGN KEY (instance_id) REFERENCES instances(id) ON DELETE CASCADE
        );
      ''');

      await b.commit(noResult: true);
      await db.insert(
        'app_setting',
        {
          'id': 1,
          'language_code': _systemLanguageCode(),  // ko/en 중 자동 선택
          // 나머지는 테이블의 DEFAULT 값 사용
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // 혹시 있으면 건너뜀
      );
    },
    onUpgrade: (db, oldV, newV) async {
      // 스키마 변경 시 버전 올리고 여기서 마이그레이션 처리
    },
  );
}



String _systemLanguageCode() {                 
  final raw = (io.Platform.localeName).toLowerCase();
  final code = raw.split(RegExp(r'[_\-.]')).first;
  const supported = {'ko', 'en'};
  return supported.contains(code) ? code : 'en';
}