import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

part 'mod_view.freezed.dart';

typedef ModId = String;

/// 테이블 렌더링용 View 모델(Installed + Preset 또는 Instance 종합 결과).
@freezed
sealed class ModView with _$ModView {
  const ModView._();

  factory ModView({
    /// 프리셋/인스턴스 Entry의 key(없으면 Mapper에서 생성 규칙 적용)
    required ModId id,

    /// 설치 여부
    required bool isInstalled,

    /// 엔트리 자체 스위치 값(JSON에 저장되는 값)
    required bool explicitEnabled,

    /// 최종 적용 상태
    required bool effectiveEnabled,

    /// 즐겨찾기
    required bool favorite,

    /// 표시 이름(Entry.workshopName 또는 Installed.workshopName 보정값)
    required String displayName,

    InstalledMod? installedRef,

    // TODO status 사용해서 mod 상태를 전달할 수 있도록 리팩토링 필요. 확장 필요. 안쓸거 같으면 그냥 제거.
    /// 상태: ok / warning / error
    required ModRowStatus status,

    /// 프리셋으로 활성화한 preset id 집합
    @Default(<String>{}) Set<String> enabledByPresets,

    /// 최근 수정 시각(정렬/표시용)
    DateTime? updatedAt,
  }) = _ModView;

  /// 별칭: 효과적 활성 상태
  bool get enabled => effectiveEnabled;

  /// 미설치 여부
  bool get isMissing => !isInstalled;

  /// 상태만 변경(헬퍼)
  ModView withStatus(ModRowStatus next) => copyWith(status: next);

  // ── empty/sentinel ───────────────────────────────────────────────────────────

  /// 비어있는(플레이스홀더) ModView.
  /// - 영속/저장 금지, 비교/초기값/가드용으로만 사용
  static final ModView empty = ModView(
    id: '',
    isInstalled: false,
    explicitEnabled: false,
    effectiveEnabled: false,
    favorite: false,
    displayName: '',
    installedRef: const InstalledMod(
      metadata: ModMetadata(
        id: '',
        name: '',
        directory: '',
        version: '',
        visibility: ModVisibility.unknown,
        tags: <String>[],),
      disabled: true,),
    status: ModRowStatus.ok,
    enabledByPresets: const {},
    updatedAt: DateTime.now(),
  );

  /// 이 뷰가 플레이스홀더인지 여부
  bool get isEmpty => id.isEmpty;
  ModId get modId {
    if (installedRef != null && installedRef!.metadata.id.isNotEmpty) {
      return installedRef!.metadata.id;
    }
    return _extractWorkshopIdFromRowKey(id);
  }
  bool get isLocalMod {
    final im = installedRef;
    if (im == null) return false;
    return im.origin == ModInstallOrigin.local;
  }
  String get version => installedRef?.version ?? "-";
  String? get installPath => !isMissing ? installedRef?.installPath : null;
}


String _extractWorkshopIdFromRowKey(String key) {
  final m = RegExp(r'_(\d+)$').firstMatch(key);
  return m?.group(1) ?? "";
}