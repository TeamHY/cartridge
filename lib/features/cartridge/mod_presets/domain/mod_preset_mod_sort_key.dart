/// 프리셋/인스턴스 화면에서 공통으로 쓰는 모드 정렬 기준 키.
enum ModSortKey {
  name,           // 이름
  version,        // 설치본 버전
  favorite,       // 모드 즐겨찾기
  enabled,        // 모드 활성 여부(Entry.enabled || preset 기여)
  enabledPreset,  // 프리셋으로 활성화된 경우 "첫 프리셋 이름" 기준
  missing,        // 미설치 여부(설치 없음 우선/후순)
  updatedAt,      // 최근 수정(Entry.updatedAt)
  lastSyncAt,     // 최근 동기화(컨테이너: Instance/ModPreset.lastSyncAt)
}

ModSortKey modSortKeyFromString(String v) {
  switch (v) {
    case 'version':       return ModSortKey.version;
    case 'favorite':      return ModSortKey.favorite;
    case 'enabled':       return ModSortKey.enabled;
    case 'enabledPreset': return ModSortKey.enabledPreset;
    case 'missing':       return ModSortKey.missing;
    case 'updatedAt':     return ModSortKey.updatedAt;
    case 'lastSyncAt':    return ModSortKey.lastSyncAt;
    case 'name':
    default:              return ModSortKey.name;
  }
}

String modSortKeyToString(ModSortKey k) {
  switch (k) {
    case ModSortKey.version:       return 'version';
    case ModSortKey.favorite:      return 'favorite';
    case ModSortKey.enabled:       return 'enabled';
    case ModSortKey.enabledPreset: return 'enabledPreset';
    case ModSortKey.missing:       return 'missing';
    case ModSortKey.updatedAt:     return 'updatedAt';
    case ModSortKey.lastSyncAt:    return 'lastSyncAt';
    case ModSortKey.name:          return 'name';
  }
}