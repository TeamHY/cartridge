import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_preset_view.freezed.dart';
part 'game_preset_view.g.dart';

/// 서버 프리셋 + 로컬 설치/활성 정보를 합친 단일 행.
/// - [allowed]는 서버 프리셋에서 !isDisable
/// - [installed]/[enabled]는 로컬 상태(설치/사용자 JSON)
@freezed
sealed class AllowedModRow with _$AllowedModRow {
  const AllowedModRow._(); // 계산/헬퍼용

  const factory AllowedModRow({
    /// 서버 프리셋의 표시 이름
    required String name,

    /// 허용 여부 (!isDisable). 기본값 true로 두되, 서버가 명시하는 값으로 덮임
    @Default(true) bool allowed,

    /// 로컬 설치 여부
    @Default(false) bool installed,

    /// 로컬 활성 여부(사용자 JSON)
    @Default(false) bool enabled,

    /// 설치 폴더 키(있다면)
    String? key,

    /// 워크샵 ID(있다면)
    String? workshopId,

    /// 특수 모드: 항상 켜짐 + 사용자 수정 불가 + 링크 비활성
    @Default(false) bool alwaysOn,
  }) = _AllowedModRow;

  factory AllowedModRow.fromJson(Map<String, dynamic> json) =>
      _$AllowedModRowFromJson(json);
}

/// 허용 모드 뷰 컨테이너.
/// - [allowedCount], [installedAllowedCount]는 서비스에서 계산/주입
/// - 추가로 편의 계산 프로퍼티 제공(enabledCount, missingCount, installedRatio)
@freezed
sealed class GamePresetView with _$GamePresetView {
  const GamePresetView._(); // 계산/헬퍼용

  const factory GamePresetView({
    /// 화면에 표시할 허용 모드들(필요 시 enabled/installed 기준으로 필터/정렬)
    @Default(<AllowedModRow>[]) List<AllowedModRow> items,

    /// 허용된 모드 개수(allowed == true)
    @Default(0) int allowedCount,

    /// 허용 + 설치된 모드 개수(allowed && installed)
    @Default(0) int installedAllowedCount,
  }) = _GamePresetView;


  factory GamePresetView.fromJson(Map<String, dynamic> json) =>
      _$GamePresetViewFromJson(json);

  /// 활성 모드 개수(JSON 반영된 enabled 카운트)
  int get enabledCount => items.where((e) => e.enabled).length;

  /// 미설치 허용 모드 개수
  int get missingCount {
    final m = allowedCount - installedAllowedCount;
    return m > 0 ? m : 0;
  }

  /// 설치 비율(허용 대비)
  double get installedRatio =>
      allowedCount == 0 ? 0.0 : installedAllowedCount / allowedCount;
}
