import 'package:cartridge/features/cartridge/record_mode/domain/models/game_preset_view.dart';
import 'package:cartridge/features/cartridge/record_mode/domain/repositories/record_mode_allowed_prefs_repository.dart';

abstract class RecordModeAllowedPrefsService {
  /// JSON 키 규칙(워크샵ID 우선, 없으면 이름)
  String keyFor(AllowedModRow r);

  /// 없으면 모두 활성(true)로 초기화하여 저장하고, 맵을 반환
  Future<Map<String, bool>> ensureInitialized(List<AllowedModRow> items);

  /// 단건 설정 및 저장
  Future<void> setEnabled(AllowedModRow row, bool value);
}

class RecordModeAllowedPrefsServiceImpl implements RecordModeAllowedPrefsService {
  final RecordModeAllowedPrefsRepository repo;
  Map<String, bool>? _cache;

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
        next[k] = true; // 최초 기본값: 활성
        changed = true;
      }
    }
    if (changed) {
      await repo.writeAll(next);
      _cache = next;
    }
    return _cache!;
  }

  @override
  Future<void> setEnabled(AllowedModRow row, bool value) async {
    _cache ??= await repo.readAll();
    final next = Map<String, bool>.from(_cache!)..[keyFor(row)] = value;
    await repo.writeAll(next);
    _cache = next;
  }
}
