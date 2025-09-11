import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/mod_preset_mod_sort_key.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'mod_preset.freezed.dart';
part 'mod_preset.g.dart';

/// 하나의 모드 프리셋(엔티티).
/// - 설치 환경과 **독립적인** 영속 데이터.
/// - 항목은 [ModEntry] (id/name/enabled/favorite/updatedAt)로만 보관.
/// - 행(View)에 필요한 설치 정보는 Service/Projector에서 합성.
/// - 정렬키/오름차순은 **모델 기본값**을 제공해 일관성 있게 동작.
@freezed
sealed class ModPreset with _$ModPreset {
  static const ModSortKey _defaultSortKey = ModSortKey.name;
  static const bool _defaultAscending = true;

  const ModPreset._();

  @Assert('id.isNotEmpty', 'ModPreset.id must not be empty')
  @Assert('name.trim().isNotEmpty', 'ModPreset.name must not be empty')
  factory ModPreset({
    /// 프리셋 식별자
    required String id,

    /// 프리셋 표시 이름
    required String name,

    /// 엔트리 목록(저장용 최소 정보 + 상태)
    @Default(<ModEntry>[]) List<ModEntry> entries,

    /// 기본 정렬Key (미지정 시 [ModSortKey.name])
    ModSortKey? sortKey,

    /// 기본 정렬 방향 (미지정 시 오름차순 true)
    bool? ascending,

    /// 프리셋 레벨 **최근 수정 시각**(이름/항목 변경 시 갱신)
    DateTime? updatedAt,

    /// 설치 목록과 **마지막 동기화 시각**(이름/존재 여부만 갱신)
    DateTime? lastSyncAt,

    /// 확장 여지(그룹/카테고리)
    String? group,

    /// 선택 카테고리 목록
    @Default(<String>[]) List<String> categories,
  }) = _ModPreset;

  /// 내부 규칙으로 id를 생성하는 팩토리 (예: `genId('mp')`)
  factory ModPreset.withGeneratedKey({
    required String Function(String prefix) genId,
    required String name,
    List<ModEntry> entries = const [],
    ModSortKey? sortKey,
    bool? ascending,
    String? group,
    List<String> categories = const [],
  }) =>
      ModPreset(
        id: genId('mp'),
        name: name,
        entries: entries,
        sortKey: sortKey,
        ascending: ascending,
        updatedAt: DateTime.now(),
        lastSyncAt: DateTime.now(),
        group: group,
        categories: categories,
      );

  factory ModPreset.fromJson(Map<String, dynamic> json) =>
      _$ModPresetFromJson(json);

  ModSortKey get effectiveSortKey => sortKey ?? _defaultSortKey;
  bool get isAscending => ascending ?? _defaultAscending;
  ModPreset duplicated(String? name) =>
      copyWith(
        id: IdUtil.genId('mp'),
        name: name ?? this.name,
        updatedAt: DateTime.now(),
      );
}
