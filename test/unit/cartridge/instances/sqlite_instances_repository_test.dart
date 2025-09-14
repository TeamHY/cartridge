import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqliteInstancesRepository', () {
    late Database db;
    late IInstancesRepository repo;

    setUp(() async {
      db = await _openMemoryDbWithSchema();
      repo = SqliteInstancesRepository(dbOpener: () async => db);
    });

    tearDown(() async => db.close());

    test('listAll(): pos ASC 순서 유지 + joins/overrides/categories/image 매핑', () async {
      // Given: i1(sprite), i2(userFile)
      final i1 = Instance(
        id: 'i1',
        name: 'One',
        optionPresetId: 'opt1',
        appliedPresets: [AppliedPresetRef(presetId: 'p1'), AppliedPresetRef(presetId: 'p2')],
        gameMode: GameMode.values[0],
        overrides: [
          ModEntry(key: 'mod.a', enabled: true, favorite: false, updatedAt: DateTime.fromMillisecondsSinceEpoch(1000)),
          ModEntry(key: 'mod.b', enabled: null, favorite: true, updatedAt: DateTime.fromMillisecondsSinceEpoch(2000)),
        ],
        sortKey: InstanceSortKey.name,
        ascending: false,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(1111),
        lastSyncAt: DateTime.fromMillisecondsSinceEpoch(2222),
        image: InstanceImage.sprite(index: 3),
        group: 'G',
        categories: const ['hard', 'fun'],
      );
      final i2 = Instance(
        id: 'i2',
        name: 'Two',
        optionPresetId: null,
        appliedPresets: [AppliedPresetRef(presetId: 'p3')],
        gameMode: GameMode.values[1],
        overrides: const [],
        sortKey: InstanceSortKey.updatedAt,
        ascending: true,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(3333),
        lastSyncAt: null,
        image: InstanceImage.userFile(path: '/tmp/pic.png', fit: BoxFit.contain),
        group: null,
        categories: const ['casual'],
      );

      await repo.upsert(i1);
      await repo.upsert(i2);

      // When
      final list = await repo.listAll();

      // Then: pos ASC = [i1, i2]
      expect(list.map((e) => e.id).toList(), ['i1', 'i2']);

      final a = list.first;
      expect(a.name, 'One');
      expect(a.optionPresetId, 'opt1');
      expect(a.appliedPresets.map((e) => e.presetId).toList(), ['p1', 'p2']);
      expect(a.overrides.length, 2);
      expect(a.overrides.first.key, 'mod.a');
      expect(a.overrides.first.enabled, isTrue);
      expect(a.overrides[1].enabled, isNull); // NULL 허용
      expect(a.categories, ['fun', 'hard']);
      expect(a.sortKey, InstanceSortKey.name);
      expect(a.ascending, isFalse);
      expect(a.updatedAt!.millisecondsSinceEpoch, 1111);
      expect(a.lastSyncAt!.millisecondsSinceEpoch, 2222);
      expect(a.group, 'G');
      expect(a.image, isA<InstanceSprite>());
      expect((a.image as InstanceSprite).index, 3);

      final b = list[1];
      expect(b.name, 'Two');
      expect(b.image, isA<InstanceUserFile>());
      final uf = b.image as InstanceUserFile;
      expect(uf.path, '/tmp/pic.png');
      expect(uf.fit, BoxFit.contain);
    });

    test('findById(): 존재 시 반환, 없으면 null', () async {
      final it = Instance(
        id: 'x',
        name: 'X',
        optionPresetId: null,
        appliedPresets: const [],
        gameMode: GameMode.values[0],
        overrides: const [],
        image: null,
        sortKey: null,
        ascending: null,
        updatedAt: null,
        lastSyncAt: null,
        group: null,
        categories: const [],
      );
      await repo.upsert(it);

      final hit = await repo.findById('x');
      expect(hit, isNotNull);

      final miss = await repo.findById('ghost');
      expect(miss, isNull, reason: '없으면 null을 반환해야 합니다');
    });

    test('upsert(): 신규 insert → pos=MAX(pos)+1, 기존 update → pos 유지 + joins/overrides/categories 교체', () async {
      // Seed: 두 개
      final a = Instance(
        id: 'a',
        name: 'A',
        optionPresetId: 'op',
        appliedPresets: [AppliedPresetRef(presetId: 'p1')],
        gameMode: GameMode.values[0],
        overrides: const [],
        image: null,
        sortKey: InstanceSortKey.name,
        ascending: true,
        updatedAt: null,
        lastSyncAt: null,
        group: null,
        categories: const ['x'],
      );
      final b = a.copyWith(id: 'b', name: 'B', categories: const ['y']);
      await repo.upsert(a);
      await repo.upsert(b);

      // 신규 c → pos=2
      final c = Instance(
        id: 'c',
        name: 'C',
        optionPresetId: null,
        appliedPresets: const [],
        gameMode: GameMode.values[1],
        overrides: const [],
        image: InstanceImage.sprite(index: 1),
        sortKey: InstanceSortKey.updatedAt,
        ascending: false,
        updatedAt: null,
        lastSyncAt: null,
        group: 'G',
        categories: const ['k'],
      );
      await repo.upsert(c);

      var rowC = (await db.query('instances', where: 'id=?', whereArgs: ['c'])).single;
      expect(rowC['pos'], 2);
      expect(rowC['image_kind'], 1);

      // a 업데이트: 이름/카테고리/overrides 교체, pos 유지(0)
      final a2 = a.copyWith(
        name: 'A2',
        overrides: [ModEntry(key: 'm', enabled: false, favorite: true)],
        categories: const ['z'],
      );
      await repo.upsert(a2);

      final rowA = (await db.query('instances', where: 'id=?', whereArgs: ['a'])).single;
      expect(rowA['pos'], 0);
      expect(rowA['name'], 'A2');

      final ovA = await db.query('instance_overrides', where: 'instance_id=?', whereArgs: ['a']);
      expect(ovA.length, 1);
      expect(ovA.single['mod_key'], 'm');

      final catA = await db.query('instance_categories', where: 'instance_id=?', whereArgs: ['a']);
      expect(catA.map((e) => e['category']).toList(), ['z']);

      final joinA = await db.query('instance_mod_presets', where: 'instance_id=?', whereArgs: ['a']);
      expect(joinA.map((e) => e['preset_id']).toList(), ['p1']);
    });

    test('removeById(): ON DELETE CASCADE로 joins/overrides/categories 함께 삭제', () async {
      final it = Instance(
        id: 'z',
        name: 'Z',
        optionPresetId: 'op',
        appliedPresets: [AppliedPresetRef(presetId: 'p')],
        gameMode: GameMode.values[0],
        overrides: [ModEntry(key: 'm', enabled: true, favorite: false)],
        image: null,
        sortKey: null,
        ascending: null,
        updatedAt: null,
        lastSyncAt: null,
        group: null,
        categories: const ['c'],
      );
      await repo.upsert(it);

      await repo.removeById('z');

      expect(await db.query('instances'), isEmpty);
      expect(await db.query('instance_mod_presets'), isEmpty);
      expect(await db.query('instance_overrides'), isEmpty);
      expect(await db.query('instance_categories'), isEmpty);
    });

    test('reorderByIds(strict=true): permutation 아니면 ArgumentError', () async {
      await repo.upsert(Instance(
        id: 'a', name: 'A', optionPresetId: null, appliedPresets: const [], gameMode: GameMode.values[0], overrides: const [], image: null, sortKey: null, ascending: null, updatedAt: null, lastSyncAt: null, group: null, categories: const [],
      ));
      await repo.upsert(Instance(
        id: 'b', name: 'B', optionPresetId: null, appliedPresets: const [], gameMode: GameMode.values[0], overrides: const [], image: null, sortKey: null, ascending: null, updatedAt: null, lastSyncAt: null, group: null, categories: const [],
      ));

      expect(
            () => repo.reorderByIds(const ['a', 'ghost'], strict: true),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('reorderByIds(strict=true): 순서대로 pos 재배치', () async {
      await repo.upsert(Instance(
        id: 'a', name: 'A', optionPresetId: null, appliedPresets: const [], gameMode: GameMode.values[0], overrides: const [], image: null, sortKey: null, ascending: null, updatedAt: null, lastSyncAt: null, group: null, categories: const [],
      ));
      await repo.upsert(Instance(
        id: 'b', name: 'B', optionPresetId: null, appliedPresets: const [], gameMode: GameMode.values[0], overrides: const [], image: null, sortKey: null, ascending: null, updatedAt: null, lastSyncAt: null, group: null, categories: const [],
      ));
      await repo.upsert(Instance(
        id: 'c', name: 'C', optionPresetId: null, appliedPresets: const [], gameMode: GameMode.values[0], overrides: const [], image: null, sortKey: null, ascending: null, updatedAt: null, lastSyncAt: null, group: null, categories: const [],
      ));

      await repo.reorderByIds(const ['b', 'c', 'a'], strict: true);
      final rows = await db.query('instances', orderBy: 'pos ASC');
      expect(rows.map((e) => e['id']).toList(), ['b', 'c', 'a']);
      expect(rows.map((e) => e['pos']).toList(), [0, 1, 2]);
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
          CREATE TABLE instances (
            id               TEXT PRIMARY KEY,
            name             TEXT NOT NULL,
            option_preset_id TEXT NULL,
            game_mode        INTEGER NOT NULL DEFAULT 0,
            sort_key         INTEGER NULL,
            ascending        INTEGER NULL,
            group_name       TEXT NULL,
            updated_at_ms    INTEGER NULL,
            last_sync_at_ms  INTEGER NULL,
            pos              INTEGER NOT NULL,
            image_kind       INTEGER NULL,
            image_index      INTEGER NULL,
            image_path       TEXT NULL,
            image_fit        INTEGER NULL
          );
        ''');
        await db.execute('CREATE INDEX idx_instances_pos    ON instances(pos);');
        await db.execute('CREATE INDEX idx_instances_option ON instances(option_preset_id);');

        await db.execute('''
          CREATE TABLE instance_mod_presets (
            instance_id TEXT NOT NULL,
            preset_id   TEXT NOT NULL,
            PRIMARY KEY (instance_id, preset_id),
            FOREIGN KEY (instance_id) REFERENCES instances(id)   ON DELETE CASCADE
          );
        ''');
        await db.execute('CREATE INDEX idx_imp_instance ON instance_mod_presets(instance_id);');
        await db.execute('CREATE INDEX idx_imp_preset   ON instance_mod_presets(preset_id);');

        await db.execute('''
          CREATE TABLE instance_overrides (
            instance_id TEXT NOT NULL,
            mod_key     TEXT NOT NULL,
            enabled     INTEGER NULL,
            favorite    INTEGER NOT NULL DEFAULT 0,
            updated_at_ms  INTEGER NOT NULL,
            PRIMARY KEY (instance_id, mod_key),
            FOREIGN KEY (instance_id) REFERENCES instances(id) ON DELETE CASCADE
          );
        ''');

        await db.execute('''
          CREATE TABLE instance_categories (
            instance_id TEXT NOT NULL,
            category    TEXT NOT NULL,
            PRIMARY KEY (instance_id, category),
            FOREIGN KEY (instance_id) REFERENCES instances(id) ON DELETE CASCADE
          );
        ''');
      },
    ),
  );
}
