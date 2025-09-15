library;

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:cartridge/features/cartridge/option_presets/data/i_option_presets_repository.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset.dart';
import 'package:cartridge/features/isaac/options/domain/models/isaac_options.dart';

class SqliteOptionPresetsRepository implements IOptionPresetsRepository {
  final Future<Database> Function() _db;

  SqliteOptionPresetsRepository({required Future<Database> Function() dbOpener}) : _db = dbOpener;

// ── Queries ───────────────────────────────────────────────────────────
  @override
  Future<List<OptionPreset>> listAll() async {
    final db = await _db();
    final rows = await db.query(
      'option_presets',
      orderBy: 'pos ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<OptionPreset?> findById(String id) async {
    final db = await _db();
    final rows = await db.query(
      'option_presets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

// ── Commands ───────────────────────────────────────────────────────────
  @override
  Future<void> upsert(OptionPreset preset) async {
    final db = await _db();
    await db.transaction((txn) async {
      // 존재 여부 확인
      final cur = await txn.query(
        'option_presets',
        columns: ['pos'],
        where: 'id = ?',
        whereArgs: [preset.id],
        limit: 1,
      );

      // 공통 컬럼(UPDATE/INSERT 공통)
      final data = <String, Object?>{
        'name'          : preset.name,
        'use_repentogon': preset.useRepentogon == null
            ? null
            : (preset.useRepentogon! ? 1 : 0),
        'options_json'  : jsonEncode(preset.options.toJson()),
        'updated_at_ms' : preset.updatedAt?.millisecondsSinceEpoch,
      };

      if (cur.isEmpty) {
        // 신규: pos = MAX(pos)+1
        final nextPos = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COALESCE(MAX(pos), -1) FROM option_presets'),
        )! + 1;

        await txn.insert('option_presets', {
          'id'  : preset.id,
          'pos' : nextPos,
          ...data,
        });
      } else {
        // 기존: id/pos 유지하고 나머지만 UPDATE (조인 안전)
        await txn.update(
          'option_presets',
          data,
          where: 'id = ?',
          whereArgs: [preset.id],
        );
      }
    });
  }

  @override
  Future<void> removeById(String id) async {
    final db = await _db();
    await db.delete('option_presets', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    final db = await _db();
    if (strict) {
      final existing = (await db.query('option_presets', columns: ['id']))
          .map((e) => e['id'] as String)
          .toSet();
      if (existing.length != orderedIds.toSet().length || !existing.containsAll(orderedIds)) {
        throw ArgumentError('orderedIds must be a permutation of existing option preset ids');
      }
    }
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update(
          'option_presets',
          {'pos': i},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
    });
  }

// ── Mapping ───────────────────────────────────────────────────────────
  // ignore: unused_element
  Map<String, Object?> _toRow(OptionPreset p, {required int pos}) => {
    'id': p.id,
    'pos': pos,
    'name': p.name,
    'use_repentogon': p.useRepentogon == null ? null : (p.useRepentogon! ? 1 : 0),
    'options_json': jsonEncode(p.options.toJson()),
    'updated_at_ms': p.updatedAt?.millisecondsSinceEpoch,
  };

  // ignore: unused_element
  OptionPreset _fromRow(Map<String, Object?> m) => OptionPreset(
    id: m['id'] as String,
    name: (m['name'] as String?) ?? '',
    useRepentogon: (m['use_repentogon'] as int?) == null
        ? null
        : ((m['use_repentogon'] as int) != 0),
    options: IsaacOptions.fromJson(
      jsonDecode((m['options_json'] as String?) ?? '{}') as Map<String, dynamic>,
    ),
    updatedAt: (m['updated_at_ms'] as int?) == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(m['updated_at_ms'] as int),
  );
}
