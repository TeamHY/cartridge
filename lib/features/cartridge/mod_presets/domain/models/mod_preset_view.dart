import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cartridge/features/cartridge/mod_presets/domain/mod_preset_mod_sort_key.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/mod_preset_mod_view_sort.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';


part 'mod_preset_view.freezed.dart';

/// 프리셋 상세 화면용 View 컨테이너.
/// - 합성/머지 로직은 Projector(Service)에서 수행하고,
///   본 클래스는 결과 데이터와 간단한 정렬/카운트 유틸만 제공합니다.
@freezed
sealed class ModPresetView with _$ModPresetView {
  const ModPresetView._(); // 계산 프로퍼티/메서드용

  @Assert('key.isNotEmpty', 'arg=key type=ModPresetView msg=빈 키는 허용되지 않습니다')
  factory ModPresetView({
    /// 프리셋 식별자
    required String key,

    /// 프리셋 표시 이름
    required String name,

    /// 화면에 렌더링할 행(View) 목록
    @Default(<ModView>[]) List<ModView> items,

    /// 총 개수(프로젝터에서 계산/주입; 미주입 시 0)
    @Default(0) int totalCount,

    /// 효과적 활성 행 수(프로젝터에서 계산/주입; 미주입 시 0)
    @Default(0) int enabledCount,

    /// 기본 정렬키(미지정 시 name), 오름차순 여부(미지정 시 true)
    ModSortKey? sortKey,
    bool? ascending,

    /// 프리셋 레벨 최근 수정 시각
    DateTime? updatedAt,
  }) = _ModPresetView;

  /// 활성 비율
  double get enabledRatio =>
      totalCount == 0 ? 0.0 : enabledCount / totalCount;

  /// 미설치 행 수 (on-the-fly 계산)
  int get missingCount => items.where((v) => v.isMissing).length;

  /// 정렬된 리스트 반환. 미지정 시 뷰의 기본값 사용(name, asc=true).
  List<ModView> sortedItems({ModSortKey? key, bool? asc}) {
    final k = key ?? sortKey ?? ModSortKey.name;
    final a = asc ?? ascending ?? true;
    final out = [...items];
    out.sort((x, y) => compareModView(k, a, x, y));
    return out;
  }
}