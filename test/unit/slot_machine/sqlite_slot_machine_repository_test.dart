import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cartridge/features/cartridge/slot_machine/data/sqlite_slot_machine_repository.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';

Future<Database> _openInMemory() async {
  // FFI 초기화
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final db = await databaseFactory.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, v) async {
          await db.execute('''
            CREATE TABLE slots (
              id TEXT PRIMARY KEY,
              pos INTEGER NOT NULL
            );
          ''');
          await db.execute('''
            CREATE TABLE slot_items (
              slot_id TEXT NOT NULL,
              position INTEGER NOT NULL,
              content TEXT NOT NULL
            );
          ''');
        },
      ));
  return db;
}

void main() {
  group('SqliteSlotMachineRepository — 인메모리 DB', () {
    late Database db;
    late SqliteSlotMachineRepository repo;

    setUp(() async {
      db = await _openInMemory();
      repo = SqliteSlotMachineRepository(dbOpener: () async => db);
    });

    tearDown(() async {
      await db.close();
    });

    test('빈 DB에서 listAll은 빈 리스트를 반환한다', () async {
      // Act
      final all = await repo.listAll();

      // Assert
      expect(all, isEmpty);
    });

    test('upsert는 신규 슬롯을 추가하고 pos는 0부터 증가한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 's1', items: ['A']));
      await repo.upsert(const Slot(id: 's2', items: ['B']));

      // Act
      final rows = await db.rawQuery('SELECT id,pos FROM slots ORDER BY pos ASC');

      // Assert
      expect(rows, hasLength(2));
      expect(rows[0]['id'], 's1');
      expect(rows[0]['pos'], 0);
      expect(rows[1]['id'], 's2');
      expect(rows[1]['pos'], 1);
    });

    test('upsert는 기존 슬롯의 pos를 보존하면서 아이템을 교체한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 's1', items: ['A']));
      await repo.upsert(const Slot(id: 's2', items: ['B']));
      final posBefore = await db.query('slots', columns: ['pos'], where: 'id=?', whereArgs: ['s1']);

      // Act
      await repo.upsert(const Slot(id: 's1', items: ['X', 'Y']));
      final s1 = await repo.findById('s1');
      final posAfter = await db.query('slots', columns: ['pos'], where: 'id=?', whereArgs: ['s1']);

      // Assert
      expect(s1!.items, ['X', 'Y']);
      expect(posBefore.first['pos'], posAfter.first['pos']);
    });

    test('listAll은 slot_items.position 순서로 아이템을 정렬해 반환한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 's1', items: ['A', 'B', 'C']));
      // Act
      final all = await repo.listAll();
      // Assert
      expect(all.single.id, 's1');
      expect(all.single.items, ['A', 'B', 'C']);
    });

    test('reorderByIds는 pos를 재배치한다(strict=true)', () async {
      // Arrange
      await repo.upsert(const Slot(id: 's1', items: ['A']));
      await repo.upsert(const Slot(id: 's2', items: ['B']));
      await repo.upsert(const Slot(id: 's3', items: ['C']));

      // Act
      await repo.reorderByIds(const ['s3', 's1', 's2']);

      // Assert
      final rows = await db.rawQuery('SELECT id FROM slots ORDER BY pos ASC');
      expect(rows.map((e) => e['id']).toList(), ['s3', 's1', 's2']);
    });

    test('reorderByIds(strict=true)에서 누락/추가가 있으면 예외를 던진다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 's1', items: ['A']));
      await repo.upsert(const Slot(id: 's2', items: ['B']));

      // Act & Assert
      await expectLater(
            () => repo.reorderByIds(const ['s1']), // 누락
        throwsArgumentError,
      );
      await expectLater(
            () => repo.reorderByIds(const ['s1', 's2', 'extra']), // 추가
        throwsArgumentError,
      );
    });

    test('removeById는 슬롯을 삭제한다', () async {
      // Arrange
      await repo.upsert(const Slot(id: 's1', items: ['A']));
      await repo.upsert(const Slot(id: 's2', items: ['B']));

      // Act
      await repo.removeById('s1');
      final all = await repo.listAll();

      // Assert
      expect(all.map((e) => e.id), ['s2']);
    });

    test('findById는 없는 경우 null을 반환한다', () async {
      // Act & Assert
      expect(await repo.findById('nope'), isNull);
    });
  });
}
