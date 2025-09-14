import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cartridge/features/cartridge/mod_presets/data/i_mod_presets_repository.dart';
import 'package:cartridge/features/cartridge/mod_presets/data/sqlite_mod_presets_repository.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';

void main() {
  // FFI init for Windows/Linux & in-memory DB tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqliteModPresetsRepository', () {
    late Database db;
    late IModPresetsRepository repo;

    setUp(() async {
      db = await _openMemoryDbWithSchema();
      repo = SqliteModPresetsRepository(dbOpener: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('listAll(): pos ASC 순서 유지 + entries 정렬/매핑', () async {
      // Given: presets a(pos=0), b(pos=1)
      await db.insert('mod_presets', {
        'id': 'a', 'pos': 0, 'name': 'A', 'ascending': 1,
      });
      await db.insert('mod_presets', {
        'id': 'b', 'pos': 1, 'name': 'B', 'ascending': 0,
      });
      // entries for a: z, a (will be ordered by mod_key ASC: a, z)
      await db.insert('mod_preset_entries', {
        'preset_id': 'a', 'mod_key': 'mod.z', 'enabled': 1, 'favorite': 0,
      });
      await db.insert('mod_preset_entries', {
        'preset_id': 'a', 'mod_key': 'mod.a', 'enabled': 0, 'favorite': 1,
      });

      // When
      final list = await repo.listAll();

      // Then
      expect(list.map((e) => e.id).toList(), ['a', 'b']);
      final a = list.firstWhere((e) => e.id == 'a');
      expect(a.entries.map((e) => e.key).toList(), ['mod.a', 'mod.z']);
      expect(a.entries.first.enabled, isFalse);
      expect(a.entries.first.favorite, isTrue);
    });

    test('findById(): 존재/없음 처리 및 entries 로드', () async {
      // Given
      await db.insert('mod_presets', {'id': 'p', 'pos': 0, 'name': 'P'});
      await db.insert('mod_preset_entries', {
        'preset_id': 'p', 'mod_key': 'k', 'enabled': 1, 'favorite': 1,
      });

      // When
      final hit = await repo.findById('p');
      final miss = await repo.findById('ghost');

      // Then
      expect(hit, isNotNull);
      expect(hit!.entries.single.key, 'k');
      expect(miss, isNull);
    });

    test('upsert(): 신규 insert → pos=MAX(pos)+1, 기존 update → pos 유지 + entries 전체 교체', () async {
      // Given: 기존 2개 (pos=0,1)
      await db.insert('mod_presets', {'id': 'a', 'pos': 0, 'name': 'A'});
      await db.insert('mod_presets', {'id': 'b', 'pos': 1, 'name': 'B'});

      // When: 신규 c upsert → pos=2
      final c = ModPreset(
        id: 'c', name: 'C', entries: [ModEntry(key: 'm1', enabled: true, favorite: false)],
      );
      await repo.upsert(c);

      // Then
      final rowC = (await db.query('mod_presets', where: 'id=?', whereArgs: ['c'])).single;
      expect(rowC['pos'], 2);

      // And: 기존 a를 업데이트(이름 변경, entries 교체)
      final aNext = ModPreset(
        id: 'a', name: 'A2', entries: [ModEntry(key: 'm2', enabled: false, favorite: true)],
      );
      await repo.upsert(aNext);

      final rowA = (await db.query('mod_presets', where: 'id=?', whereArgs: ['a'])).single;
      expect(rowA['pos'], 0); // pos 유지
      expect(rowA['name'], 'A2');

      final entriesA = await db.query('mod_preset_entries', where: 'preset_id=?', whereArgs: ['a']);
      expect(entriesA.length, 1);
      expect(entriesA.single['mod_key'], 'm2');
    });

    test('removeById(): ON DELETE CASCADE로 entries 함께 삭제', () async {
      // Given
      await db.insert('mod_presets', {'id': 'x', 'pos': 0, 'name': 'X'});
      await db.insert('mod_preset_entries', {'preset_id': 'x', 'mod_key': 'k', 'enabled': 1, 'favorite': 0});

      // When
      await repo.removeById('x');

      // Then
      final left = await db.query('mod_preset_entries');
      expect(left, isEmpty);
    });

    test('reorderByIds(strict=true): permutation 아니면 ArgumentError', () async {
      // Given
      await db.insert('mod_presets', {'id': 'a', 'pos': 0, 'name': 'A'});
      await db.insert('mod_presets', {'id': 'b', 'pos': 1, 'name': 'B'});

      // When/Then
      expect(
            () => repo.reorderByIds(['a', 'ghost'], strict: true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reorderByIds(strict=true): 순서대로 pos 재배치', () async {
      // Given
      await db.insert('mod_presets', {'id': 'a', 'pos': 0, 'name': 'A'});
      await db.insert('mod_presets', {'id': 'b', 'pos': 1, 'name': 'B'});
      await db.insert('mod_presets', {'id': 'c', 'pos': 2, 'name': 'C'});

      // When
      await repo.reorderByIds(['b', 'c', 'a'], strict: true);

      // Then
      final rows = await db.query('mod_presets', orderBy: 'pos ASC');
      expect(rows.map((e) => e['id']).toList(), ['b', 'c', 'a']);
      expect(rows.map((e) => e['pos']).toList(), [0, 1, 2]);
    });

    test('upsertEntry(): 신규 insert 시 0/1 매핑 및 updated_at_ms 설정', () async {
      // Given
      await db.insert('mod_presets', {'id': 'p', 'pos': 0, 'name': 'P'});

      // When
      await repo.upsertEntry('p', ModEntry(key: 'k', enabled: null, favorite: true));

      // Then
      final row = (await db.query('mod_preset_entries', where: 'preset_id=? AND mod_key=?', whereArgs: ['p', 'k'])).single;
      expect(row['enabled'], 0); // null → 0
      expect(row['favorite'], 1);
      expect(row['updated_at_ms'], isNotNull);
    });

    test('updateEntryState(): 미존재 + null변경 → no-op, 미존재 + enabled=true → insert', () async {
      // Given
      await db.insert('mod_presets', {'id': 'p', 'pos': 0, 'name': 'P'});

      // When: no-op
      await repo.updateEntryState('p', 'k');
      var rows = await db.query('mod_preset_entries', where: 'preset_id=? AND mod_key=?', whereArgs: ['p', 'k']);
      expect(rows, isEmpty);

      // When: enabled=true → insert (favorite는 0)
      await repo.updateEntryState('p', 'k', enabled: true);
      rows = await db.query('mod_preset_entries', where: 'preset_id=? AND mod_key=?', whereArgs: ['p', 'k']);
      expect(rows.single['enabled'], 1);
      expect(rows.single['favorite'], 0);
    });

    test('updateEntryState(): 기존 행 → 변경 없음(no-op) / favorite 토글만 갱신', () async {
      // Given
      await db.insert('mod_presets', {'id': 'p', 'pos': 0, 'name': 'P'});
      await db.insert('mod_preset_entries', {
        'preset_id': 'p', 'mod_key': 'k', 'enabled': 1, 'favorite': 0, 'updated_at_ms': 1000,
      });

      // When: no-op
      await repo.updateEntryState('p', 'k');
      var row = (await db.query('mod_preset_entries', where: 'preset_id=? AND mod_key=?', whereArgs: ['p', 'k'])).single;
      expect(row['updated_at_ms'], 1000);
      expect(row['favorite'], 0);

      // When: favorite만 true로
      await repo.updateEntryState('p', 'k', favorite: true);
      row = (await db.query('mod_preset_entries', where: 'preset_id=? AND mod_key=?', whereArgs: ['p', 'k'])).single;
      expect(row['favorite'], 1);
      expect(row['enabled'], 1); // 그대로
      expect(row['updated_at_ms'], greaterThan(1000));
    });

    test('deleteEntry(): 단건 삭제', () async {
      // Given
      await db.insert('mod_presets', {'id': 'p', 'pos': 0, 'name': 'P'});
      await db.insert('mod_preset_entries', {'preset_id': 'p', 'mod_key': 'k', 'enabled': 1, 'favorite': 0});

      // When
      await repo.deleteEntry('p', 'k');

      // Then
      final rows = await db.query('mod_preset_entries', where: 'preset_id=? AND mod_key=?', whereArgs: ['p', 'k']);
      expect(rows, isEmpty);
    });
  });
}

Future<Database> _openMemoryDbWithSchema() async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE mod_presets(
            id                TEXT PRIMARY KEY,
            pos               INTEGER NOT NULL,
            name              TEXT    NOT NULL,
            sort_key          INTEGER NULL,
            ascending         INTEGER NULL,
            updated_at_ms     INTEGER NULL,
            last_sync_at_ms   INTEGER NULL,
            group_name        TEXT NULL,
            categories_json   TEXT NOT NULL DEFAULT '[]'
          );
        ''');
        await db.execute('CREATE INDEX idx_mod_presets_pos ON mod_presets(pos);');

        await db.execute('''
          CREATE TABLE mod_preset_entries(
            preset_id     TEXT NOT NULL,
            mod_key       TEXT NOT NULL,
            enabled       INTEGER NOT NULL DEFAULT 0,
            favorite      INTEGER NOT NULL DEFAULT 0,
            updated_at_ms INTEGER NULL,
            PRIMARY KEY (preset_id, mod_key),
            FOREIGN KEY (preset_id) REFERENCES mod_presets(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('CREATE INDEX idx_mpe_preset ON mod_preset_entries(preset_id);');
      },
    ),
  );
}
