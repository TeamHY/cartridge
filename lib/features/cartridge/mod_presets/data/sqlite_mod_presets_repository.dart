import 'package:sqflite/sqflite.dart';

import 'package:cartridge/features/cartridge/mod_presets/data/i_mod_presets_repository.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/mod_preset_mod_sort_key.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_entry.dart';

class SqliteModPresetsRepository implements IModPresetsRepository {
  final Future<Database> Function() _db;
  SqliteModPresetsRepository({required Future<Database> Function() dbOpener}) : _db = dbOpener;

// ── Queries ────────────────────────────────────────────────────────────────
  @override
  Future<List<ModPreset>> listAll() async {
    final db = await _db();
    final rows = await db.query('mod_presets', orderBy: 'pos ASC');

    final out = <ModPreset>[];
    for (final m in rows) {
      final id = m['id'] as String;
      final entries = await _loadEntries(db, id);

      out.add(ModPreset(
        id: id,
        name: (m['name'] as String?) ?? '',
        entries: entries,
        sortKey: _intToSortKey(m['sort_key']),
        ascending: _intToBoolNullable(m['ascending']),
        updatedAt: _msToDate(m['updated_at_ms']),
        lastSyncAt: _msToDate(m['last_sync_at_ms']),
        group: m['group_name'] as String?,
        // categories_json은 그대로 JSON 문자열이므로 서비스에서 처리하거나
        // 필요 시 여기서 decode해서 List<String>으로 변환하도록 확장 가능
        // 일단 기존 계약 유지 위해 skip (모델 Default는 [] 이므로 안전)
      ));
    }
    return out;
  }

  @override
  Future<ModPreset?> findById(String id) async {
    final db = await _db();
    final rows = await db.query('mod_presets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;

    final m = rows.first;
    final entries = await _loadEntries(db, id);

    return ModPreset(
      id: id,
      name: (m['name'] as String?) ?? '',
      entries: entries,
      sortKey: _intToSortKey(m['sort_key']),
      ascending: _intToBoolNullable(m['ascending']),
      updatedAt: _msToDate(m['updated_at_ms']),
      lastSyncAt: _msToDate(m['last_sync_at_ms']),
      group: m['group_name'] as String?,
    );
  }

// ── Commands ───────────────────────────────────────────────────────────────
  @override
  Future<void> upsert(ModPreset preset) async {
    final db = await _db();
    await db.transaction((txn) async {
      // 현재 pos 조회
      final cur = await txn.query(
        'mod_presets',
        columns: ['pos'],
        where: 'id = ?',
        whereArgs: [preset.id],
        limit: 1,
      );

      final data = <String, Object?>{
        'name'           : preset.name,
        'sort_key'       : _sortKeyToInt(preset.sortKey),
        'ascending'      : _boolToInt(preset.ascending),
        'updated_at_ms'  : preset.updatedAt?.millisecondsSinceEpoch,
        'last_sync_at_ms': preset.lastSyncAt?.millisecondsSinceEpoch,
        'group_name'     : preset.group,
      };

      if (cur.isEmpty) {
        // 신규: pos = MAX(pos)+1 → INSERT
        final nextPos = Sqflite.firstIntValue(
          await txn.rawQuery('SELECT COALESCE(MAX(pos), -1) FROM mod_presets'),
        )! + 1;

        await txn.insert('mod_presets', {
          'id'  : preset.id,
          'pos' : nextPos,
          ...data,
        });
      } else {
        // 기존: UPDATE (id/pos는 건드리지 않음) → 조인 테이블 안전
        await txn.update(
          'mod_presets',
          data,
          where: 'id = ?',
          whereArgs: [preset.id],
        );
      }

      // entries 전체 교체는 그대로 OK
      await txn.delete('mod_preset_entries', where: 'preset_id = ?', whereArgs: [preset.id]);
      for (final e in preset.entries) {
        await txn.insert(
          'mod_preset_entries',
          _toEntryRow(preset.id, e),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }


  @override
  Future<void> removeById(String id) async {
    final db = await _db();
    await db.delete('mod_presets', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reorderByIds(List<String> orderedIds, {bool strict = true}) async {
    final db = await _db();
    if (strict) {
      final existing = (await db.query('mod_presets', columns: ['id'])).map((e) => e['id'] as String).toSet();
      if (existing.length != orderedIds.toSet().length || !existing.containsAll(orderedIds)) {
        throw ArgumentError('orderedIds must be a permutation of existing mod preset ids');
      }
    }
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update('mod_presets', {'pos': i}, where: 'id = ?', whereArgs: [orderedIds[i]]);
      }
    });
  }

  // ── Commands (엔트리 단건 최적화) ─────────────────────────────────────────────
  @override
  Future<void> upsertEntry(String presetId, ModEntry entry) async {
    final db = await _db();
    final now = entry.updatedAt?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'mod_preset_entries',
      {
        'preset_id': presetId,
        'mod_key': entry.key,
        'enabled': (entry.enabled ?? false) ? 1 : 0, // ⬅️ 0/1로 강제
        'favorite': entry.favorite ? 1 : 0,
        'updated_at_ms': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteEntry(String presetId, String modKey) async {
    final db = await _db();
    await db.delete('mod_preset_entries',
        where: 'preset_id = ? AND mod_key = ?', whereArgs: [presetId, modKey]);
  }

  @override
  Future<void> updateEntryState(
      String presetId,
      String modKey, {
        bool? enabled,   // null = 변경 없음
        bool? favorite,  // null = 변경 없음
      }) async {
    final db = await _db();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 존재 여부만 확인
    final hit = await db.query(
      'mod_preset_entries',
      where: 'preset_id = ? AND mod_key = ?',
      whereArgs: [presetId, modKey],
      limit: 1,
    );

    if (hit.isEmpty) {
      // 둘 다 null이면 실제 변화가 없으니 no-op
      if (enabled == null && favorite == null) return;

      // 새로 만든다: null은 0으로 저장(이진 규약 유지)
      await db.insert(
        'mod_preset_entries',
        {
          'preset_id': presetId,
          'mod_key': modKey,
          'enabled': (enabled ?? false) ? 1 : 0,   // ⬅️ null → 0
          'favorite': (favorite ?? false) ? 1 : 0, // ⬅️ null → 0
          'updated_at_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return;
    }

    // 기존 행이 있는 경우: 변경 요청된 필드만 갱신
    if (enabled == null && favorite == null) return; // 변경 없음(no-op)

    final update = <String, Object?>{
      'updated_at_ms': now,
    };
    if (enabled != null)  update['enabled']  = enabled ? 1 : 0;   // ⬅️ 0/1
    if (favorite != null) update['favorite'] = favorite ? 1 : 0;  // ⬅️ 0/1

    await db.update(
      'mod_preset_entries',
      update,
      where: 'preset_id = ? AND mod_key = ?',
      whereArgs: [presetId, modKey],
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────────
  Future<List<ModEntry>> _loadEntries(Database db, String presetId) async {
    final rows = await db.query(
      'mod_preset_entries',
      where: 'preset_id = ?',
      whereArgs: [presetId],
      orderBy: 'mod_key ASC',
    );
    return rows.map(_entryFromRow).toList(growable: false);
  }

  Map<String, Object?> _toEntryRow(String presetId, ModEntry e) => {
    'preset_id': presetId,
    'mod_key': e.key,
    'enabled': (e.enabled ?? false) ? 1 : 0, // ⬅️ null을 0으로 저장
    'favorite': e.favorite ? 1 : 0,
    'updated_at_ms': e.updatedAt?.millisecondsSinceEpoch,
  };

  ModEntry _entryFromRow(Map<String, Object?> r) => ModEntry(
    key: (r['mod_key'] as String?) ?? '',
    enabled: ((r['enabled'] as int?) ?? 0) != 0,   // ⬅️ 항상 true/false
    favorite: ((r['favorite'] as int?) ?? 0) != 0,
    updatedAt: _msToDate(r['updated_at_ms']),
    // 저장하지 않음
    workshopId: null,
    workshopName: null,
  );

// ── helpers ────────────────────────────────────────────────────────────────
  int? _boolToInt(bool? v) => v == null ? null : (v ? 1 : 0);
  bool? _intToBoolNullable(Object? v) =>
      v == null ? null : ((v as int) != 0);

  int? _sortKeyToInt(ModSortKey? k) => k?.index;
  ModSortKey? _intToSortKey(Object? v) =>
      (v is int)
          ? ModSortKey.values[
      (v < 0 || v >= ModSortKey.values.length) ? 0 : v]
          : null;

  DateTime? _msToDate(Object? v) =>
      (v is int) ? DateTime.fromMillisecondsSinceEpoch(v) : null;
}
