/// 인스턴스 목록/상세 테이블 전용 정렬 키.
/// - 프리셋과는 요구가 달라 별도 키로 분리합니다.
enum InstanceSortKey {
  name,                 // 이름
  version,              // 설치본 버전
  favorite,       // 모드 즐겨찾기
  enabled,              // 모드 활성 여부(Entry.enabled || preset 기여)
  enabledByPresetCount, // 프리셋으로 활성화된 경우, 프리셋 갯수
  enabledPreset,  // 프리셋으로 활성화된 경우 "첫 프리셋 이름" 기준
  missing,              // 미설치 여부
  updatedAt,            // 엔트리 최신 수정
  lastSyncAt,           // 컨테이너(Instance) 최근 동기화 — 행 레벨엔 값이 없으므로 폴백 정렬
}

/// 문자열 ↔ 키 매핑 (JSON 직렬화용)
InstanceSortKey instanceSortKeyFromString(String v) {
  switch (v) {
    case 'version':              return InstanceSortKey.version;
    case 'favorite':             return InstanceSortKey.favorite;
    case 'enabled':              return InstanceSortKey.enabled;
    case 'enabledByPresetCount': return InstanceSortKey.enabledByPresetCount;
    case 'enabledPreset':        return InstanceSortKey.enabledPreset;
    case 'missing':              return InstanceSortKey.missing;
    case 'updatedAt':            return InstanceSortKey.updatedAt;
    case 'lastSyncAt':           return InstanceSortKey.lastSyncAt;
    case 'name':
    default:                     return InstanceSortKey.name;
  }
}

String instanceSortKeyToString(InstanceSortKey k) {
  switch (k) {
    case InstanceSortKey.version:              return 'version';
    case InstanceSortKey.favorite:             return 'favorite';
    case InstanceSortKey.enabled:              return 'enabled';
    case InstanceSortKey.enabledByPresetCount: return 'enabledByPresetCount';
    case InstanceSortKey.enabledPreset:        return 'enabledPreset';
    case InstanceSortKey.missing:              return 'missing';
    case InstanceSortKey.updatedAt:            return 'updatedAt';
    case InstanceSortKey.lastSyncAt:           return 'lastSyncAt';
    case InstanceSortKey.name:                 return 'name';
  }
}
