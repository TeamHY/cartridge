import 'package:cartridge/features/cartridge/instances/domain/instance_mod_sort_key.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/applied_preset_ref.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/game_mode.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_image.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:sqflite/sqflite.dart';

import 'i_instances_repository.dart';

class SqliteInstancesRepository implements IInstancesRepository {
  final Future<Database> Function() _db;
  SqliteInstancesRepository({required Future<Database> Function() dbOpener}) : _db = dbOpener;

  @override
  Future<List<Instance>> listAll() async {
    final db = await _db();
    final rows = await db.query('instances', orderBy: 'pos ASC');
    final out = <Instance>[];
    for (final r in rows) {
      final id = r['id'] as String;

      final joins = await db.query(
        'instance_mod_presets',
        where: 'instance_id = ?',
        whereArgs: [id],
        // orderBy 제거 (순서 무의미). 필요하면 preset_id로만 고정 정렬
        // orderBy: 'preset_id ASC',
      );
      final applied = [
        for (final j in joins)
          AppliedPresetRef(presetId: j['preset_id'] as String),
      ];

      final ovRows = await db.query(
        'instance_overrides',
        where: 'instance_id = ?',
        whereArgs: [id],
      );
      final overrides = [
        for (final o in ovRows)
          ModEntry(
            key:       o['mod_key'] as String,
            enabled:   (o['enabled'] as int?) == null ? null : ((o['enabled'] as int) != 0),
            favorite:  ((o['favorite'] as int?) ?? 0) != 0,
            updatedAt: DateTime.fromMillisecondsSinceEpoch((o['updated_at_ms'] as int?) ?? 0),
          ),
      ];

      final cats = await db.query(
        'instance_categories',
        where: 'instance_id = ?',
        whereArgs: [id],
      );

      out.add(Instance(
        id: id,
        name: r['name'] as String,
        optionPresetId: r['option_preset_id'] as String?,
        appliedPresets: applied,
        gameMode: GameMode.values[(r['game_mode'] as int?) ?? 0],
        overrides: overrides,
        sortKey: (r['sort_key'] as int?) != null ? InstanceSortKey.values[r['sort_key'] as int] : null,
        ascending: (r['ascending'] as int?) == null ? null : ((r['ascending'] as int) != 0),
        updatedAt: (r['updated_at_ms'] as int?) != null ? DateTime.fromMillisecondsSinceEpoch(r['updated_at_ms'] as int) : null,
        lastSyncAt:(r['last_sync_at_ms'] as int?) != null ? DateTime.fromMillisecondsSinceEpoch(r['last_sync_at_ms'] as int) : null,
        image: _readImage(r),
        group: r['group_name'] as String?,
        categories: cats.map((e) => e['category'] as String).toList(growable: false),
      ));
    }
    return out;
  }

  @override
  Future<Instance?> findById(String id) async {
    final db = await _db();

    // 1) 본체 한 건
    final rows = await db.query(
      'instances',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final r = rows.first;

    // 2) 조인: applied presets (set semantics)
    final joins = await db.query(
      'instance_mod_presets',
      where: 'instance_id = ?',
      whereArgs: [id],
    );
    final applied = [
      for (final j in joins) AppliedPresetRef(presetId: j['preset_id'] as String),
    ];

    // 3) overrides (tri-state enabled: NULL/0/1)
    final ovRows = await db.query(
      'instance_overrides',
      where: 'instance_id = ?',
      whereArgs: [id],
    );
    final overrides = [
      for (final o in ovRows)
        ModEntry(
          key: o['mod_key'] as String,
          enabled: (o['enabled'] as int?) == null ? null : ((o['enabled'] as int) != 0),
          favorite: ((o['favorite'] as int?) ?? 0) != 0,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (o['updated_at_ms'] as int?) ?? 0,
          ),
        ),
    ];

    // 4) categories
    final cats = await db.query(
      'instance_categories',
      where: 'instance_id = ?',
      whereArgs: [id],
    );

    // 5) 매핑
    return Instance(
      id: id,
      name: r['name'] as String,
      optionPresetId: r['option_preset_id'] as String?,
      appliedPresets: applied,
      gameMode: GameMode.values[(r['game_mode'] as int?) ?? 0],
      overrides: overrides,
      sortKey: (r['sort_key'] as int?) != null
          ? InstanceSortKey.values[r['sort_key'] as int]
          : null,
      ascending: (r['ascending'] as int?) == null
          ? null
          : ((r['ascending'] as int) != 0),
      updatedAt: (r['updated_at_ms'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(r['updated_at_ms'] as int)
          : null,
      lastSyncAt: (r['last_sync_at_ms'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(r['last_sync_at_ms'] as int)
          : null,
      image: _readImage(r),
      group: r['group_name'] as String?,
      categories: cats.map((e) => e['category'] as String).toList(growable: false),
    );
  }

  @override
  Future<void> upsert(Instance i) async {
    final db = await _db();
    await db.transaction((txn) async {
      // pos: 신규면 MAX+1, 기존이면 유지
      final cur = await txn.query('instances', columns: ['pos'], where: 'id=?', whereArgs: [i.id], limit: 1);
      final pos = cur.isEmpty
          ? (Sqflite.firstIntValue(await txn.rawQuery('SELECT COALESCE(MAX(pos), -1) FROM instances'))! + 1)
          : (cur.first['pos'] as int);

      await txn.insert(
        'instances',
        {
          'id': i.id,
          'name': i.name,
          'option_preset_id': i.optionPresetId,
          'game_mode': i.gameMode.index,
          'sort_key': i.sortKey?.index,
          'ascending': i.ascending == null ? null : (i.ascending! ? 1 : 0),
          'group_name': i.group,
          'updated_at_ms': i.updatedAt?.millisecondsSinceEpoch,
          'last_sync_at_ms': i.lastSyncAt?.millisecondsSinceEpoch,
          'pos': pos,
          ..._writeImage(i.image),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete('instance_mod_presets', where: 'instance_id=?', whereArgs: [i.id]);
      final setIds = <String>{};
      for (final a in i.appliedPresets) {
        if (setIds.add(a.presetId)) {
          await txn.insert(
            'instance_mod_presets',
            {'instance_id': i.id, 'preset_id': a.presetId},
            conflictAlgorithm: ConflictAlgorithm.ignore, // 혹시 중복이면 무시
          );
        }
      }

      await txn.delete('instance_overrides', where: 'instance_id=?', whereArgs: [i.id]);
      for (final o in i.overrides) {
        await txn.insert('instance_overrides', {
          'instance_id': i.id,
          'mod_key': o.key,
          'enabled': o.enabled == null ? null : (o.enabled! ? 1 : 0),
          'favorite': o.favorite ? 1 : 0,
          'updated_at_ms': o.updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        });
      }

      await txn.delete('instance_categories', where: 'instance_id=?', whereArgs: [i.id]);
      for (final c in i.categories) {
        await txn.insert('instance_categories', {
          'instance_id': i.id,
          'category': c,
        });
      }
    });
  }

  @override
  Future<void> removeById(String id) async {
    final db = await _db();
    await db.delete('instances', where: 'id=?', whereArgs: [id]); // CASCADE
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    final db = await _db();
    if (strict) {
      final existing = (await db.query('instances', columns: ['id'])).map((e) => e['id'] as String).toSet();
      if (existing.length != orderedIds.toSet().length || !existing.containsAll(orderedIds)) {
        throw ArgumentError('orderedIds must be a permutation of existing instance ids');
      }
    }
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update('instances', {'pos': i}, where: 'id=?', whereArgs: [orderedIds[i]]);
      }
    });
  }

  // ── image packing helpers ──
  Map<String, Object?> _writeImage(InstanceImage? img) {
    if (img is InstanceSprite) {
      return {
        'image_kind': 1,
        'image_index': img.index,
        'image_path': null,
        'image_fit': null,
      };
    }
    if (img is InstanceUserFile) {
      return {
        'image_kind': 2,
        'image_index': null,
        'image_path': img.path,
        'image_fit': img.fit.index,
      };
    }
    return {'image_kind': null, 'image_index': null, 'image_path': null, 'image_fit': null};
  }

  InstanceImage? _readImage(Map<String, Object?> r) {
    final kind = r['image_kind'] as int?;
    if (kind == 1) {
      return InstanceImage.sprite(index: r['image_index'] as int);
    } else if (kind == 2) {
      return InstanceImage.userFile(
        path: r['image_path'] as String,
        fit: BoxFit.values[(r['image_fit'] as int?) ?? BoxFit.cover.index],
      );
    }
    return null;
  }
}
