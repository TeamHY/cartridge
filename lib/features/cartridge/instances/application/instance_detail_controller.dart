import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/log.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/application/instances_controller.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_mod_sort_key.dart';
import 'package:cartridge/features/cartridge/instances/domain/instance_mod_view_sort.dart';
import 'package:cartridge/features/cartridge/instances/domain/instances_service.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/applied_preset_ref.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_view.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

/// # InstanceDetailController
///
/// 인스턴스 상세 화면의 **Application 컨트롤러**.
///
/// - 상태 타입은 항상 `InstanceView`(뷰 모델)만 노출합니다.
/// - IsaacEnvironment(설치 경로/설치 목록 해석)는 **Service 계층**에서만 다룹니다
///   → 컨트롤러는 `IsaacEnvironmentService`를 직접 참조하지 않습니다.
/// - 정렬(Sort)은 **즉시 화면(View) 재정렬**하고, **정렬 기준은 저장소(Repository)에 영구 저장**합니다.
///
/// 정렬 버튼 동작:
/// 1) 현재 `items`를 즉시 재정렬해 화면에 반영
/// 2) 같은 기준을 Service를 통해 저장소에 저장(영구화)
class InstanceDetailController
    extends AutoDisposeFamilyAsyncNotifier<InstanceView, String> {
  InstancesService get _instances => ref.read(instancesServiceProvider);
  late String _instanceId;

  @override
  Future<InstanceView> build(String argInstanceId) async {
    _instanceId = argInstanceId;

    final view = await _instances.getViewById(_instanceId);
    if (view == null) {
      throw StateError('Instance not found: $_instanceId');
    }

    return _resortBy(view.sortKey!, view.ascending ?? true, view);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 내부 유틸
  // ───────────────────────────────────────────────────────────────────────────

  /// 지정된 정렬 기준으로 `view.items`를 재정렬한 사본을 반환.
  InstanceView _resortBy(InstanceSortKey key, bool asc, InstanceView view) {
    final sorted = sortInstanceModViews(view.items, key: key, ascending: asc);
    return view.copyWith(sortKey: key, ascending: asc, items: sorted);
  }


  Future<void> _refresh() async {
    final fresh = await _instances.getViewById(_instanceId);
    if (fresh == null) return;
    state = AsyncData(fresh);
    _touchList();
  }

  Future<Result<T>> _refreshWhenOk<T>(Result<T> res) async {
    return await res.map(
      ok:       (r) async { await _refresh(); return r; },
      notFound: (r) async => r,
      invalid:  (r) async => r,
      conflict: (r) async => r,
      failure:  (r) async => r,
    );
  }

  Future<void> refreshInstalled() async {
    await _refresh();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 정렬: 즉시 재정렬 + 저장(영구화)
  // ───────────────────────────────────────────────────────────────────────────

  /// **토글 정렬**: 같은 키면 방향 토글, 다른 키면 오름차순으로 시작.
  /// 1) 현재 리스트 즉시 재정렬 → 2) 저장소에 정렬 기준 저장
  Future<void> toggleSort(InstanceSortKey key) async {
    final cur = state.valueOrNull;
    if (cur == null) return;

    final nextAsc = (cur.sortKey == key) ? !(cur.ascending ?? true) : true;

    // ① 즉시 재정렬(화면 반영)
    state = AsyncData(_resortBy(key, nextAsc, cur));

    // ② 저장(영구화)
    await _instances.setSort(_instanceId, key, ascending: nextAsc);
  }

  /// **정렬 기준 명시 설정**:
  /// 1) 즉시 재정렬 → 2) 저장(영구화)
  Future<void> setSort(InstanceSortKey key, {required bool ascending}) async {
    final cur = state.valueOrNull;
    if (cur == null) return;

    state = AsyncData(_resortBy(key, ascending, cur));
    await _instances.setSort(_instanceId, key, ascending: ascending);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 편집/상호작용(모두 Service 경유) + 최신 View 재적용
  // ───────────────────────────────────────────────────────────────────────────

  /// 프리셋 이름 변경 후, 최신 View를 현재 정렬 기준으로 재적용.
  Future<void> rename(String name) async {
    await _instances.rename(_instanceId, name);
    await _refresh();
  }

  /// 즐겨찾기 토글 (rowKey = ModView.key)
  Future<void> toggleFavorite(ModView item) async {
    await setFavorite(item, item.enabled, !item.favorite);
  }

  /// 활성/비활성 토글 (rowKey = ModView.key)
  Future<void> toggleEnabled(ModView item) async {
    await setEnabled(item, !item.enabled);
  }

  /// 즐겨찾기 설정 (rowKey = ModView.key)
  Future<void> setFavorite(ModView item, bool? enabled, bool favorite) async {
    await _instances.setItemState(
      instanceId: _instanceId,
      item    : item,
      enabled : enabled,
      favorite : favorite,
    );
    await _refresh();
  }

  /// 활성/비활성 설정 (rowKey = ModView.key)
  Future<void> setEnabled(ModView item, bool enabled) async {
    final bool presetEnabled = item.enabledByPresets.isNotEmpty;
    final bool? next = mapCheckedToOverrideEnabled(
      checked: enabled,
      presetEnabled: presetEnabled,
    );
    await _instances.setItemState(
      instanceId: _instanceId,
      item    : item,
      enabled : next,
    );
    await _refresh();
  }

  /// 항목 제거
  Future<void> removeItem(ModView item) async {
    await _instances.deleteItem(
      instanceId: _instanceId,
      itemId    : item.id,
    );
    await _refresh();
  }

  /// 배치: 즐겨찾기 일괄 설정
  Future<void> bulkFavorite(Iterable<ModView> items, bool fav) async {
    await _instances.bulkSetItemState(
      instanceId: _instanceId,
      items   : items,
      favorite: fav,
    );
    await _refresh();
  }

  /// 배치: 활성 일괄 설정
  Future<void> bulkEnable(Iterable<ModView> items, bool enabled) async {
    await _instances.bulkSetItemState(
      instanceId: _instanceId,
      items: items,
      enabled: enabled,
    );
    await _refresh();
  }

  /// 프리셋 삭제(라우팅은 호출자에서 처리).
  Future<void> deleteInstance() async {
    await _instances.delete(_instanceId);
  }


  Future<Result<Instance?>> setImageToSprite(String instanceId, int index) async {
    final res = await _instances.setImageToSprite(instanceId: instanceId, index: index);
    return _refreshWhenOk(res);
  }

  Future<Result<Instance?>> setImageToUserFile(String instanceId, String path, {BoxFit fit = BoxFit.cover}) async {
    final res = await _instances.setImageToUserFile(instanceId: instanceId, path: path, fit: fit);
    return _refreshWhenOk(res);
  }

  Future<Result<Instance?>> setImageToRandomSprite(String instanceId, {int? seed}) async {
    final res = await _instances.setImageToRandomSprite(instanceId: instanceId, seed: seed);
    return _refreshWhenOk(res);
  }

  Future<Result<Instance?>> clearImage(String instanceId) async {
    final res = await _instances.clearImage(instanceId);
    return _refreshWhenOk(res);
  }

  // ───────── 속성/프리셋/정렬 ─────────
  Future<void> setOptionPreset(String? optionPresetId) async {
    if (!state.hasValue) return;
    final curView = state.requireValue;        // InstanceView
    if (optionPresetId == curView.optionPresetId) return;

    // 1) 저장 (서비스는 Instance?를 반환)
    final res = await _instances.setOptionPreset(curView.id, optionPresetId);

    await res.map(
      ok:       (r) async {
        state = AsyncData(curView.copyWith(
          optionPresetId: optionPresetId,
          updatedAt: r.data?.updatedAt,
        ));
      },
      notFound: (_) async {},
      invalid:  (_) async {},
      conflict: (_) async {},
      failure:  (_) async {},
    );

  }

  Future<void> setPresetIds(List<AppliedPresetRef> ids) async {
    if (!state.hasValue) return;
    final cur = state.requireValue;

    // 현재 appliedPresets(라벨 뷰)와 새 refs(값 객체)의 "서명"을 만들어 비교 (순서 포함)
    String sigLabels(List<AppliedPresetLabelView> a) =>
        a.map((e) => '${e.presetId}:${e.isMandatory}').join('|');
    String sigRefs(List<AppliedPresetRef> a) =>
        a.map((e) => '${e.presetId}:${e.isMandatory}').join('|');

    final currSig = sigLabels(cur.appliedPresets);
    final nextSig = sigRefs(ids);

    if (currSig == nextSig) return; // 변경 없음

    final saved = await _instances.replaceAppliedPresets(instanceId: cur.id, refs: ids);
    if (saved == null) return;

    // 프리셋 변경은 items/카운트에 영향 → 재빌드
    await _refresh();
  }

  Future<void> addPreset(String presetId) async {
    if (!state.hasValue) return;
    final cur = state.requireValue;

    // 이미 적용되어 있으면 no-op
    if (cur.appliedPresets.any((e) => e.presetId == presetId)) return;

    // 프리셋 추가 (불필요한 inst-enable 델타는 정리하고 싶으면 pruneRedundant: true)
    final saved = await _instances.addModPresetUsingUseCase(
      instanceId: cur.id,
      presetId: presetId,
      pruneRedundant: true,
    );
    if (saved == null) return;

    await _refresh();
  }

  Future<void> removePreset(String presetId, {bool keepContributions = false}) async {
    if (!state.hasValue) {
      logW("InstanceDetailController", "state에 value가 없습니다.");
      return;
    }
    final cur = state.requireValue;

    // 적용 안되어 있으면 no-op
    if (!cur.appliedPresets.any((e) => e.presetId == presetId)) {
      logW("InstanceDetailController", "appliedPresets에 preset이 없습니다.");
      return;
    }

    // keepContributions=true 이면 UseCase가 overrides 보강해서 동작 유지
    final saved = await _instances.removeModPresetUsingUseCase(
      instanceId: cur.id,
      presetId: presetId,
      keepContributions: keepContributions,
    );
    if (saved == null) {
      logE("InstanceDetailController", "프리셋 제거를 실패했습니다.");
      return;
    }
    logI("InstanceDetailController", "성공적으로 프리셋을 제거했습니다.");
    await _refresh();
  }

  /// 체크박스 클릭 결과를 오버라이드 enabled(3값)로 변환
  /// - checked=true  -> enabled=true
  /// - checked=false -> presetEnabled ? enabled=false : enabled=null
  bool? mapCheckedToOverrideEnabled({
    required bool checked,
    required bool presetEnabled,
  }) {
    if (checked) return true;
    return presetEnabled ? false : null;
  }

  void _touchList() => ref.invalidate(instancesControllerProvider);
}


/// Application 컨트롤러 Provider (family: instanceId)
/// - 상태 타입: `InstanceView`
/// - 환경/설치 목록은 Service에서 해석
final instanceDetailControllerProvider =
AutoDisposeAsyncNotifierProvider.family<InstanceDetailController, InstanceView, String>(
  InstanceDetailController.new,
);

// 키->행 맵 파생
final instanceItemsByKeyProvider =
AutoDisposeProvider.family<Map<String, ModView>, String>((ref, presetId) {
  final app = ref.watch(instanceDetailControllerProvider(presetId));
  return app.maybeWhen(
    data: (v) => { for (final m in v.items) m.id: m },
    orElse: () => const {},
  );
});

