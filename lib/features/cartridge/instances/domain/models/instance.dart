import 'package:fluent_ui/fluent_ui.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

part 'instance.freezed.dart';
part 'instance.g.dart';

/// 실행 단위 **Instance** 저장 모델.
///
/// - 연결: `OptionPreset`(최대 1개) → [optionPresetId],
///        `ModPreset`(0~N개) → [appliedPresets]
/// - 상태 표현은 **ModEntry 기반 오버라이드**로만 관리:
///   - 엔트리가 **없으면** 프리셋 결과에 따름
///   - 엔트리가 **있고 enabled=true**면 **직접 활성**
///   - 엔트리가 **있고 enabled=false**면 **강제 비활성**
/// - 정렬키/방향은 기본값을 제공: [effectiveSortKey], [isAscending]
@freezed
sealed class Instance with _$Instance {
  static const InstanceSortKey _defaultSortKey = InstanceSortKey.name;
  static const bool _defaultAscending = true;

  const Instance._();

  @Assert('id.isNotEmpty', 'Instance.id must not be empty')
  @Assert('name.trim().isNotEmpty', 'Instance.name must not be empty')
  factory Instance({
    // 식별
    required String id,
    required String name,

    // 연결된 옵션 프리셋(게임 옵션을 저장해놓은 프리셋)
    String? optionPresetId,
    /// 적용한 모드 프리셋들(0~N). 모드 프리셋의 entries는 '의도'로만 사용.
    @Default(<AppliedPresetRef>[]) List<AppliedPresetRef> appliedPresets,

    // TODO Game 모드로 인스턴스 단위로 게임 플레이 할때 hook에 활용하도록 확장 필요.
    // Record 모드는 레거시에 의존하고 있어서 합치지 못했음.
    // battle 모드는 변경 사항이 너무 많아서 생략함.
    // 필요 없으면 제거 고려.
    /// 게임 모드 (예: 'normal', 'battle', 'record', 'vanilla')
    @Default(GameMode.normal)
    GameMode gameMode,

    /// 인스턴스 오버라이드 엔트리
    /// - 엔트리 없으면 프리셋 결과 따름
    /// - 엔트리.enabled=true  → 직접 활성
    /// - 엔트리.enabled=false → 강제 비활성
    /// - favorite      : 이 인스턴스에서만 보이는 즐겨찾기 표시
    @Default(<ModEntry>[]) List<ModEntry> overrides,

    // 정렬/표시
    InstanceSortKey? sortKey,
    bool? ascending,

    // 메타
    DateTime? updatedAt,   // 최근 수정일(이름/항목/정렬 변경 시 갱신)
    DateTime? lastSyncAt,  // 설치 목록과 최근 동기화 시각(이름/존재여부 갱신)

    InstanceImage? image,

    // TODO 확장 여지(그룹/카테고리)
    String? group,
    @Default(<String>[]) List<String> categories,
  }) = _Instance;

  /// JSON 역직렬화
  factory Instance.fromJson(Map<String, dynamic> json) =>
      _$InstanceFromJson(json);

  /// 정렬키 기본값 적용
  InstanceSortKey get effectiveSortKey => sortKey ?? _defaultSortKey;

  /// 정렬방향 기본값 적용
  bool get isAscending => ascending ?? _defaultAscending;

  factory Instance.withGeneratedKey({
    required String Function(String prefix) genId,
    required String name,
    String? optionPresetId,
    List<AppliedPresetRef> appliedPresets = const <AppliedPresetRef>[],
    GameMode gameMode = GameMode.normal,
    List<ModEntry> overrides = const <ModEntry>[],
    InstanceSortKey? sortKey,
    bool? ascending,
    String? group,
    List<String> categories = const <String>[],
  }) => Instance(
    id: genId('inst'),
    name: name,
    optionPresetId: optionPresetId,
    appliedPresets: appliedPresets,
    gameMode: gameMode,
    overrides: overrides,
    sortKey: sortKey,
    ascending: ascending,
    updatedAt: DateTime.now(),
    lastSyncAt: DateTime.now(),
    group: group,
    categories: categories,
  );

  Instance duplicated(String? name) =>
      copyWith(
        id: IdUtil.genId('inst'),
        name: name ?? this.name,
        updatedAt: DateTime.now(),
      );
}

// instance.dart (추가: 런타임 인덱스, 프리셋 id 셋, 오버라이드 헬퍼)
extension InstanceRuntime on Instance {
  /// O(1) 접근을 위한 키-엔트리 맵 (런타임 캐시용)
  Map<String, ModEntry> get overrideIndex =>
      {for (final e in overrides) e.key: e};

  /// 적용한 프리셋 id 집합
  Set<String> get appliedPresetIds =>
      {for (final r in appliedPresets) r.presetId};

  /// 델타 조작 도우미 — 토글/강제ON/강제OFF/즐겨찾기
  Instance toggleEnable(
      String key, {
        required bool presetEnabled,
        String? nameHint,
        String? workshopId,
      }) {
    final now = DateTime.now();
    final cur = overrideIndex[key];

    if (cur == null) {
      // 중립(null) → 켬(true)
      final e = ModEntry(
        key: key,
        workshopId: workshopId,
        workshopName: nameHint,
        enabled: true,
        favorite: false,
        updatedAt: now,
      );
      return copyWith(overrides: [...overrides, e], updatedAt: now);
    } else {
      final e = cur.enabled; // bool?
      bool? nextEnabled;
      if (e == true) {
        nextEnabled = presetEnabled ? false : null;
      } else if (e == false) {
        nextEnabled = true;
      } else { // null
        nextEnabled = true;
      }
      final next = cur.copyWith(enabled: nextEnabled, updatedAt: now);

      // Pruning: enabled=null && favorite=false → 엔트리 제거
      if (next.enabled == null && !next.favorite) {
        final list = overrides.where((x) => x.key != key).toList();
        return copyWith(overrides: list, updatedAt: now);
      }
      final list = overrides.map((e) => e.key == key ? next : e).toList();
      return copyWith(overrides: list, updatedAt: DateTime.now());
    }
  }

  Instance setEnable(
      String key,
      bool? on, {
        String? nameHint,
        String? workshopId,
      }) {
    final now = DateTime.now();
    final idx = overrideIndex;
    final cur = idx[key];

    if (cur == null) {
      if (on == null) return this;
      final e = ModEntry(
        key: key,
        workshopId: workshopId,
        workshopName: nameHint,
        enabled: on,
        favorite: false,
        updatedAt: now,
      );
      return copyWith(overrides: [...overrides, e], updatedAt: now);
    } else {
      final next = cur.copyWith(enabled: on, updatedAt: now);
      // Pruning: enabled=null && favorite=false → 엔트리 제거
      if (next.enabled == null && !next.favorite) {
        final list = overrides.where((e) => e.key != key).toList();
        return copyWith(overrides: list, updatedAt: now);
      }
      final list = overrides.map((e) => e.key == key ? next : e).toList();
      return copyWith(overrides: list, updatedAt: now);
    }
  }

  Instance toggleFavorite(String key, {String? nameHint, String? workshopId}) {
    final idx = overrideIndex;
    final cur = idx[key];
    if (cur == null) {
      final e = ModEntry(
        key: key,
        workshopId: workshopId,
        workshopName: nameHint,
        enabled: false, // 즐겨찾기만 먼저 줄 수 있음(비활성+즐찾)
        favorite: true,
        updatedAt: DateTime.now(),
      );
      return copyWith(overrides: [...overrides, e], updatedAt: DateTime.now());
    } else {
      final next = cur.copyWith(favorite: !cur.favorite, updatedAt: DateTime.now());
      final list = overrides.map((e) => e.key == key ? next : e).toList();
      return copyWith(overrides: list, updatedAt: DateTime.now());
    }
  }
}

extension InstanceImageOps on Instance {
  Instance setSprite(int index) =>
      copyWith(image: InstanceImage.sprite(index: index));

  Instance setUserFile(String path, {BoxFit fit = BoxFit.cover}) =>
      copyWith(image: InstanceImage.userFile(path: path, fit: fit));

  Instance clearImage() => copyWith(image: null);

  bool get hasSprite => image is InstanceSprite;
  bool get hasUserFile => image is InstanceUserFile;
}