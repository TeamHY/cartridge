import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cartridge/features/cartridge/option_presets/data/i_option_presets_repository.dart';
import 'package:cartridge/features/cartridge/option_presets/data/sqlite_option_presets_repository.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';

void main() {
  // FFI init for Windows/Linux & in-memory DB tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqliteOptionPresetsRepository', () {
    late Database db;
    late IOptionPresetsRepository repo;

    setUp(() async {
      db = await _openMemoryDbWithSchema();
      repo = SqliteOptionPresetsRepository(dbOpener: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('listAll(): pos ASC 정렬로 반환', () async {
      // Given: 비정상 순서로 직접 insert
      await db.insert('option_presets', _row(
        id: 'b', pos: 2, name: 'B', useRepentogon: null,
        options: IsaacOptions.fromJson({}),
      ));
      await db.insert('option_presets', _row(
        id: 'a', pos: 0, name: 'A', useRepentogon: 1,
        options: IsaacOptions.fromJson({}),
      ));
      await db.insert('option_presets', _row(
        id: 'c', pos: 1, name: 'C', useRepentogon: 0,
        options: IsaacOptions.fromJson({}),
      ));

      // When
      final list = await repo.listAll();

      // Then: pos 0,1,2 순으로 a,c,b
      expect(list.map((e) => e.id).toList(), ['a', 'c', 'b']);
    });

    test('findById(): 존재하지 않으면 null', () async {
      // When
      final got = await repo.findById('nope');
      // Then
      expect(got, isNull);
    });

    test('upsert(): 신규 insert 시 pos=MAX(pos)+1 할당', () async {
      // Given: 기존 pos가 0,1로 채워짐
      await db.insert('option_presets', _row(
        id: 'a', pos: 0, name: 'A', useRepentogon: 1,
        options: IsaacOptions.fromJson({}),
      ));
      await db.insert('option_presets', _row(
        id: 'b', pos: 1, name: 'B', useRepentogon: 0,
        options: IsaacOptions.fromJson({}),
      ));

      // When: 신규 upsert(id=c)
      final presetC = OptionPreset(
        id: 'c',
        name: 'C',
        useRepentogon: null,
        options: IsaacOptions.fromJson({}),
      );
      await repo.upsert(presetC);

      // Then: pos는 2로 배정
      final row = (await db.query('option_presets', where: 'id = ?', whereArgs: ['c'])).single;
      expect(row['pos'], 2);
      expect(row['name'], 'C');
      expect(row['use_repentogon'], isNull);
    });

    test('upsert(): 기존 row 업데이트 시 pos 유지', () async {
      // Given: 기존 row pos=5
      await db.insert('option_presets', _row(
        id: 'x', pos: 5, name: 'Old', useRepentogon: 1,
        options: IsaacOptions.fromJson({'Some': 1}),
        updatedAtMs: 1000,
      ));

      // When: 이름/옵션/updated_at_ms만 변경해 upsert
      final next = OptionPreset(
        id: 'x',
        name: 'New',
        useRepentogon: false,
        options: IsaacOptions.fromJson({'Changed': true}),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(9999),
      );
      await repo.upsert(next);

      // Then: pos는 5 유지, 나머지 변경
      final row = (await db.query('option_presets', where: 'id = ?', whereArgs: ['x'])).single;
      expect(row['pos'], 5);
      expect(row['name'], 'New');
      expect(row['use_repentogon'], 0);
      expect(row['updated_at_ms'], 9999);
    });

    test('removeById(): 지정 id 삭제', () async {
      // Given
      await db.insert('option_presets', _row(
        id: 'a', pos: 0, name: 'A', useRepentogon: 1,
        options: IsaacOptions.fromJson({}),
      ));
      await db.insert('option_presets', _row(
        id: 'b', pos: 1, name: 'B', useRepentogon: 0,
        options: IsaacOptions.fromJson({}),
      ));

      // When
      await repo.removeById('a');

      // Then
      final ids = (await db.query('option_presets', columns: ['id']))
          .map((e) => e['id']).toList();
      expect(ids, ['b']);
    });

    test('reorderByIds(strict=true): permutation 아니면 ArgumentError', () async {
      // Given
      await db.insert('option_presets', _row(id: 'a', pos: 0, name: 'A', useRepentogon: 1, options: IsaacOptions.fromJson({})));
      await db.insert('option_presets', _row(id: 'b', pos: 1, name: 'B', useRepentogon: 0, options: IsaacOptions.fromJson({})));

      // When/Then
      expect(
            () => repo.reorderByIds(['a', 'b', 'ghost'], strict: true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reorderByIds(strict=true): 순서대로 pos 재배치', () async {
      // Given
      await db.insert('option_presets', _row(id: 'a', pos: 0, name: 'A', useRepentogon: 1, options: IsaacOptions.fromJson({})));
      await db.insert('option_presets', _row(id: 'b', pos: 1, name: 'B', useRepentogon: 0, options: IsaacOptions.fromJson({})));
      await db.insert('option_presets', _row(id: 'c', pos: 2, name: 'C', useRepentogon: null, options: IsaacOptions.fromJson({})));

      // When
      await repo.reorderByIds(['b', 'c', 'a'], strict: true);

      // Then: pos는 0,1,2로 재배치
      final rows = await db.query('option_presets', orderBy: 'pos ASC');
      expect(rows.map((e) => e['id']).toList(), ['b', 'c', 'a']);
      expect(rows.map((e) => e['pos']).toList(), [0, 1, 2]);
    });

    test('useRepentogon tri-state: null/0/1 매핑', () async {
      // Given
      await db.insert('option_presets', _row(id: 'n', pos: 0, name: 'N', useRepentogon: null, options: IsaacOptions.fromJson({})));
      await db.insert('option_presets', _row(id: 'f', pos: 1, name: 'F', useRepentogon: 0, options: IsaacOptions.fromJson({})));
      await db.insert('option_presets', _row(id: 't', pos: 2, name: 'T', useRepentogon: 1, options: IsaacOptions.fromJson({})));

      // When
      final list = await repo.listAll();
      final m = {for (final p in list) p.id: p};

      // Then
      expect(m['n']!.useRepentogon, isNull);
      expect(m['f']!.useRepentogon, isFalse);
      expect(m['t']!.useRepentogon, isTrue);
    });

    test('options_json/updated_at_ms: JSON/타임스탬프 round-trip', () async {
      // Given
      final orig = OptionPreset(
        id: 'opt',
        name: 'Opt',
        useRepentogon: true,
        options: IsaacOptions.fromJson({'MusicVolume': 0.42, 'Fullscreen': true}),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1234567890),
      );

      // When
      await repo.upsert(orig);
      final got = await repo.findById('opt');

      // Then
      expect(got, isNotNull);
      expect(got!.name, 'Opt');
      expect(got.useRepentogon, isTrue);
      expect(got.updatedAt!.millisecondsSinceEpoch, 1234567890);
      // options JSON 동등성(구조적 비교)
      expect(got.options.toJson(), orig.options.toJson());
    });
  });
}

Future<Database> _openMemoryDbWithSchema() async {
  return databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE option_presets(
            id               TEXT PRIMARY KEY,
            pos              INTEGER NOT NULL,
            name             TEXT    NOT NULL,
            use_repentogon   INTEGER NULL,
            options_json     TEXT    NOT NULL,
            updated_at_ms    INTEGER NULL
          );
        ''');
        await db.execute('CREATE INDEX idx_option_presets_pos ON option_presets(pos);');
      },
    ),
  );
}

Map<String, Object?> _row({
  required String id,
  required int pos,
  required String name,
  required int? useRepentogon,
  required IsaacOptions options,
  int? updatedAtMs,
}) {
  return {
    'id': id,
    'pos': pos,
    'name': name,
    'use_repentogon': useRepentogon,
    'options_json': jsonEncode(options.toJson()), // store as JSON string via toString for test seed
    'updated_at_ms': updatedAtMs,
  };
}
