import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_mod_sort_key.dart';

int _cmp<T extends Comparable>(T a, T b, bool asc) => asc ? a.compareTo(b) : b.compareTo(a);
int _ts(DateTime? dt) => dt?.millisecondsSinceEpoch ?? -1;
String _lc(String s) => s.toLowerCase();

/// 인스턴스 화면 전용 ModView 비교자
int compareInstanceModView(InstanceSortKey key, bool ascending, ModView a, ModView b) {
  if (a.favorite != b.favorite) {
    return a.favorite ? -1 : 1; // true가 항상 위로
  }

  switch (key) {
    case InstanceSortKey.name:
      return _defaultCmp(a, b, ascending);

    case InstanceSortKey.enabled:
    // 효과적 활성(effectiveEnabled) 별칭: v.enabled
      final ae = a.effectiveEnabled ? 0 : 1;
      final be = b.effectiveEnabled ? 0 : 1;
      final z = _cmp(ae, be, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case InstanceSortKey.version:
      final av = (a.installedRef != null) ? a.installedRef!.metadata.version : "-";
      final bv = (b.installedRef != null) ? b.installedRef!.metadata.version : "-";
      final z = _cmp(av, bv, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case InstanceSortKey.favorite:
      final ae = a.favorite ? 0 : 1;
      final be = b.favorite ? 0 : 1;
      final z = _cmp(ae, be, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case InstanceSortKey.enabledByPresetCount:
      final an = a.enabledByPresets.isNotEmpty ? a.enabledByPresets.length : 0;
      final bn = b.enabledByPresets.isNotEmpty ? b.enabledByPresets.length : 0;
      final z = _cmp(an, bn, ascending);
      return z != 0 ? z : _defaultCmp(a, b, ascending);

    case InstanceSortKey.enabledPreset:
    // 모드 프리셋 적용 갯수
      final an = a.enabledByPresets.isNotEmpty ? a.enabledByPresets.length : 0;
      final bn = b.enabledByPresets.isNotEmpty ? b.enabledByPresets.length : 0;
      final z = _cmp(an, bn, ascending);
      return z != 0 ? z :  _defaultCmp(a, b, ascending);

    case InstanceSortKey.missing:
      final ai = a.isMissing ? 1 : 0;
      final bi = b.isMissing ? 1 : 0;
      final z = _cmp(ai, bi, ascending);
      return z != 0 ? z : _defaultCmp(a, b, ascending);

    case InstanceSortKey.updatedAt:
      final z = _cmp(_ts(a.updatedAt), _ts(b.updatedAt), ascending);
      return z != 0 ? z : _defaultCmp(a, b, ascending);

    case InstanceSortKey.lastSyncAt:
    // 행(View)에는 lastSyncAt이 없음 → 이름 기준 폴백
      return _defaultCmp(a, b, ascending);
  }
}

int _defaultCmp(ModView a, ModView b, bool ascending) {
  // 1) 이름
  final r1 = _cmp(_lc(a.displayName), _lc(b.displayName), ascending);
  if (r1 != 0) return r1;

  // 2) 버전
  final av = a.installedRef?.metadata.version ?? '';
  final bv = b.installedRef?.metadata.version ?? '';
  final r2 = _cmp(av, bv, ascending);
  if (r2 != 0) return r2;

  // 3) 최종 결정자: id는 정방향(항상 동일)으로 고정
  return a.id.compareTo(b.id);
}

/// 인스턴스 전용 ModView 리스트 정렬 (불변 리스트 반환)
List<ModView> sortInstanceModViews(
    Iterable<ModView> items, {
      required InstanceSortKey key,
      bool ascending = true,
    }) {
  final out = [...items];
  out.sort((a, b) => compareInstanceModView(key, ascending, a, b));
  return out;
}
