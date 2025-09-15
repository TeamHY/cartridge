import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

part 'instance_view.freezed.dart';


/// # InstanceView
/// 인스턴스 상세 화면에서 사용하는 **행 리스트 + 메타** 컨테이너.
/// - 합성/머지 로직은 Projector/Service에서 수행하세요.
/// - 본 클래스는 결과 데이터와 정렬/카운트 유틸만 제공합니다.
///
/// ## Notes/Constraints
/// - 본 View는 **경량 컨테이너**로 유지합니다. 의존 View를 중첩하지 않습니다.
///   - 예: `List<ModPresetView>`, `OptionPresetView`를 직접 보관하지 않음.
///   - 이유: 투영(Projection) 순환/중복 계산/직렬화 비용 증가를 피하기 위함.
/// - 관련 View가 필요할 때는 Service 헬퍼를 사용하세요.
///   - [InstancesService.getViewWithRelated] → `(InstanceView, List<ModPresetView>, OptionPresetView?)`
///
/// ## See also
/// - [InstanceProjector]
/// - [InstancesService.getViewWithRelated]
@freezed
sealed class InstanceView with _$InstanceView {
  const InstanceView._(); // 계산 프로퍼티/유틸용

  factory InstanceView({
    /// 뷰 식별자(Instance.id를 그대로 사용)
    required String id,

    /// 인스턴스 표시 이름
    required String name,

    String? optionPresetId,

    /// 화면에 렌더링할 ModView 목록
    @Default(<ModView>[]) List<ModView> items,

    /// 총 개수(프로젝터가 계산/주입; 미주입 시 0)
    @Default(0) int totalCount,

    /// 효과적 활성 행 수(프로젝터가 계산/주입; 미주입 시 0)
    @Default(0) int enabledCount,

    /// 미설치 갯수
    @Default(0) int missingCount,

    /// 정렬 기본값(미지정 시 name), 오름차순 여부(미지정 시 true)
    InstanceSortKey? sortKey,
    bool? ascending,

    /// 게임 모드(표시/필터용)
    @Default(GameMode.normal)
    GameMode gameMode,

    /// 메타
    DateTime? updatedAt,   // 최근 수정일(이름/항목/정렬 변경 시 갱신)
    DateTime? lastSyncAt,  // 설치 목록과 최근 동기화 시각(이름/존재여부 갱신)

    InstanceImage? image,

    /// 확장 여지(그룹/카테고리)
    String? group,
    @Default(<String>[]) List<String> categories,

    /// 적용된 프리셋(참조용)
    @Default(<AppliedPresetLabelView>[]) List<AppliedPresetLabelView> appliedPresets,
  }) = _InstanceView;

  /// 활성 비율
  double get enabledRatio =>
      totalCount == 0 ? 0.0 : enabledCount / totalCount;

  /// 정렬된 ModView 리스트 반환.
  /// - 미지정 시 뷰의 기본값 사용(name, asc=true)
  List<ModView> sortedItems({InstanceSortKey? key, bool? asc}) {
    final k = key ?? sortKey ?? InstanceSortKey.name;
    final a = asc ?? ascending ?? true;
    final out = [...items];
    out.sort((x, y) => compareInstanceModView(k, a, x, y));
    return out;
  }

  /// 비어있는 sentinel 뷰.
  static final InstanceView empty = InstanceView(
    id: '',
    name: '',
    items: const <ModView>[],
    optionPresetId: null,
    totalCount: 0,
    enabledCount: 0,
    sortKey: null,           // 정렬 요청 시 name/asc=true로 폴백
    ascending: true,
    gameMode: GameMode.normal,
    updatedAt: null,
    lastSyncAt: null,
    group: null,
    categories: const <String>[],
    appliedPresets: const <AppliedPresetLabelView>[],
  );

  bool get isEmpty => id.isEmpty;

  bool get isNotEmpty => id.isNotEmpty;
}

@freezed
sealed class AppliedPresetLabelView with _$AppliedPresetLabelView {
  const AppliedPresetLabelView._();

  @Assert('presetId.isNotEmpty', 'AppliedPresetRef.presetId must not be empty')
  factory AppliedPresetLabelView({
    required String presetId,
    required String presetName,
    @Default(false) bool isMandatory,
  }) = _AppliedPresetLabelView;
}

