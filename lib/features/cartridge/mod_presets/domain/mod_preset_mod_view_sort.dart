import 'package:cartridge/features/cartridge/mod_presets/domain/mod_preset_mod_sort_key.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

int _cmp<T extends Comparable>(T a, T b, bool asc) => asc ? a.compareTo(b) : b.compareTo(a);
int _ts(DateTime? dt) => dt?.millisecondsSinceEpoch ?? -1;
String _lc(String s) => s.toLowerCase();

/// 공용 ModView 비교자 (프리셋/공용에서 사용)
int compareModView(ModSortKey key, bool ascending, ModView a, ModView b) {
  if (a.favorite != b.favorite) {
    return a.favorite ? -1 : 1; // true가 항상 위로
  }

  switch (key) {
    case ModSortKey.name:
      return _defaultCmp(a, b, ascending);

    case ModSortKey.version:
      final av = (a.installedRef != null) ? a.installedRef!.metadata.version : "-";
      final bv = (b.installedRef != null) ? b.installedRef!.metadata.version : "-";
      final z = _cmp(av, bv, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case ModSortKey.favorite:
      final ae = a.favorite ? 0 : 1;
      final be = b.favorite ? 0 : 1;
      final z = _cmp(ae, be, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case ModSortKey.enabled:
    // 효과적 활성(effectiveEnabled) 별칭: v.enabled
      final ae = a.enabled ? 0 : 1;
      final be = b.enabled ? 0 : 1;
      final z = _cmp(ae, be, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case ModSortKey.enabledPreset:
    // 모드 프리셋 적용 갯수
      final an = a.enabledByPresets.isNotEmpty ? a.enabledByPresets.length : 0;
      final bn = b.enabledByPresets.isNotEmpty ? b.enabledByPresets.length : 0;
      final z = _cmp(an, bn, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case ModSortKey.missing:
      final ai = a.isMissing ? 1 : 0;
      final bi = b.isMissing ? 1 : 0;
      final z = _cmp(ai, bi, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case ModSortKey.updatedAt:
      final z = _cmp(_ts(a.updatedAt), _ts(b.updatedAt), ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case ModSortKey.lastSyncAt:
    // 행(View) 레벨에는 lastSyncAt이 없음 → 이름으로 폴백
      return  _defaultCmp(a, b, ascending);
  }
}

int _defaultCmp(ModView a, ModView b, bool ascending) => _cmp(_lc(a.displayName), _lc(b.displayName), ascending);

/// 공용 ModView 리스트 정렬 (불변 리스트 반환)
List<ModView> sortModPresetModViews(
    Iterable<ModView> items, {
      required ModSortKey key,
      bool ascending = true,
    }) {
  final out = [...items];
  out.sort((a, b) => compareModView(key, ascending, a, b));
  return out;
}