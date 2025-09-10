import 'package:sqflite/sqlite_api.dart';

import 'package:cartridge/features/cartridge/slot_machine/data/i_slot_machine_repository.dart';
import 'package:cartridge/features/cartridge/slot_machine/domain/models/slot.dart';



class SqliteSlotMachineRepository implements ISlotMachineRepository {
  final Future<Database> Function() _db;

  SqliteSlotMachineRepository({required Future<Database> Function() dbOpener})
      : _db = dbOpener;

  @override
  Future<List<Slot>> listAll() async {
    final db = await _db();
    final slots = await db.query('slots', orderBy: 'pos ASC');
    final out = <Slot>[];
    for (final s in slots) {
      final id = s['id'] as String;
      final itemsRows = await db.query(
        'slot_items',
        where: 'slot_id = ?',
        whereArgs: [id],
        orderBy: 'position ASC',
      );
      out.add(Slot(
        id: id,
        items: itemsRows.map((r) => r['content'] as String).toList(growable: false),
      ));
    }
    return out;
  }

  @override
  Future<Slot?> findById(String id) async {
    final db = await _db();
    final hit = await db.query('slots', where: 'id = ?', whereArgs: [id], limit: 1);
    if (hit.isEmpty) return null;
    final items = await db.query(
      'slot_items',
      where: 'slot_id = ?',
      whereArgs: [id],
      orderBy: 'position ASC',
    );
    return Slot(
      id: id,
      items: items.map((e) => e['content'] as String).toList(growable: false),
    );
  }

  @override
  Future<void> upsert(Slot slot) async {
    final db = await _db();
    await db.transaction((txn) async {
      // 현재 pos 확인 (없으면 최대 pos + 1)
      final cur = await txn.query(
        'slots',
        columns: ['pos'],
        where: 'id = ?',
        whereArgs: [slot.id],
        limit: 1,
      );
      int pos;
      if (cur.isEmpty) {
        final maxRow = await txn.rawQuery('SELECT COALESCE(MAX(pos), -1) AS m FROM slots');
        final m = (maxRow.first['m'] as int);
        pos = m + 1;
      } else {
        pos = cur.first['pos'] as int;
      }

      await txn.insert(
        'slots',
        {'id': slot.id, 'pos': pos},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('slot_items', where: 'slot_id = ?', whereArgs: [slot.id]);
      for (int i = 0; i < slot.items.length; i++) {
        await txn.insert('slot_items', {
          'slot_id': slot.id,
          'content': slot.items[i],
          'position': i,
        });
      }
    });
  }

  @override
  Future<void> removeById(String id) async {
    final db = await _db();
    await db.delete('slots', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    final db = await _db();
    if (strict) {
      final existing = (await db.query('slots', columns: ['id']))
          .map((e) => e['id'] as String)
          .toSet();
      if (existing.length != orderedIds.toSet().length ||
          !existing.containsAll(orderedIds)) {
        throw ArgumentError('orderedIds must be a permutation of existing slot ids');
      }
    }
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update('slots', {'pos': i},
            where: 'id = ?', whereArgs: [orderedIds[i]]);
      }
    });
  }
}
