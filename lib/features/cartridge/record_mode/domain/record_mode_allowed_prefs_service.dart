import 'dart:async';

import 'package:cartridge/features/cartridge/record_mode/domain/models/game_preset_view.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/record_mode_allowed_prefs_repository.dart';

abstract class RecordModeAllowedPrefsService {
  /// JSON 키 규칙(워크샵ID 우선, 없으면 이름)
  String keyFor(AllowedModRow r);

  /// 없으면 모두 활성(true)로 초기화하여 저장하고, 맵을 반환
  Future<Map<String, bool>> ensureInitialized(List<AllowedModRow> items);

  /// 단건 설정 및 저장
  Future<void> setEnabled(AllowedModRow row, bool value);

  Future<void> setManyByRows(Iterable<AllowedModRow> rows, bool value);

  Future<void> flush();
}

class RecordModeAllowedPrefsServiceImpl implements RecordModeAllowedPrefsService {
  final RecordModeAllowedPrefsRepository repo;
  Map<String, bool>? _cache;
  final Map<String, bool> _pending = {};
  Timer? _debounce;
  static const _debounceDur = Duration(milliseconds: 350);
  RecordModeAllowedPrefsServiceImpl(this.repo);

  @override
  String keyFor(AllowedModRow r) {
    final w = r.workshopId;
    if (w != null && w.isNotEmpty) return 'wid:$w';
    return 'name:${r.name}';
  }

  @override
  Future<Map<String, bool>> ensureInitialized(List<AllowedModRow> items) async {
    _cache ??= await repo.readAll();
    var changed = false;
    final next = Map<String, bool>.from(_cache!);

    for (final r in items) {
      final k = keyFor(r);
      if (!next.containsKey(k)) {
        next[k] = r.alwaysOn ? true : (r.installed == true);
        changed = true;
      }
    }
    if (changed) {
      await repo.writeAll(next);
      _cache = next;
    }
    return _cache!;
  }

  void _scheduleFlush() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDur, () async {
      if (_cache == null || _pending.isEmpty) return;
      final merged = Map<String, bool>.from(_cache!)..addAll(_pending);
      _pending.clear();
      await repo.writeAll(merged);
      _cache = merged;
    });
  }

  @override
  Future<void> setEnabled(AllowedModRow row, bool value) async {
    _cache ??= await repo.readAll();
    final k = keyFor(row);
    _cache![k] = value;
    _pending[k] = value;
    _scheduleFlush();
  }

  @override
  Future<void> setManyByRows(Iterable<AllowedModRow> rows, bool value) async {
    _cache ??= await repo.readAll();
    for (final r in rows) {
      final k = keyFor(r);
      _cache![k] = value;
      _pending[k] = value;
    }
    _scheduleFlush();
  }

  @override
  Future<void> flush() async {
    _debounce?.cancel();
    _debounce = null;
    if (_cache == null || _pending.isEmpty) return;
    final merged = Map<String, bool>.from(_cache!)..addAll(_pending);
    _pending.clear();
    await repo.writeAll(merged);
    _cache = merged;
  }
}
