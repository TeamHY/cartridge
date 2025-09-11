import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/instances/domain/instances_service.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/applied_preset_ref.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_view.dart';
import 'package:cartridge/features/isaac/mod/domain/models/seed_mode.dart';

/// {@template instances_controller}
/// # InstancesController
///
/// 인스턴스 **뷰(InstanceView)** 목록을 다루는 Application Controller.
///
/// - 상태 타입: `AsyncValue<List<InstanceView>>`
/// - 유스케이스:
///   - 목록 로드/새로고침
///   - 인스턴스 생성/복제/삭제
///   - (경량) 활성 모드 수 조회
///
/// ## 설계 원칙
/// - 설치/환경 해석은 **Service 계층(InstancesService)** 에서만 수행한다.
///   → Controller는 Isaac 환경/설치를 직접 다루지 않는다.
/// {@endtemplate}
class InstancesController extends AutoDisposeAsyncNotifier<List<InstanceView>> {
  InstancesService get _instances => ref.read(instancesServiceProvider);

  @override
  Future<List<InstanceView>> build() => _instances.listAllViews();

  /// 목록 강제 새로고침(뷰 모델 기준).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _instances.listAllViews());
  }

  Future<Result<T>> _refreshWhenOk<T>(Result<T> res) async {
    return await res.map(
      ok:       (r) async { await refresh(); return r; },
      notFound: (r) async => r,
      invalid:  (r) async => r,
      conflict: (r) async => r,
      failure:  (r) async => r,
    );
  }

  /// 인스턴스 생성 후 목록 갱신.
  ///
  /// - 환경/설치 목록 해석은 Service 내부에서 처리된다.
  /// - 반환: 생성된 인스턴스 id (실패 시 null)
  Future<Result<Instance?>> createInstance({
    required String name,
    required List<String> presetIds,
    required String? optionPresetId,
    SeedMode seedMode = SeedMode.allOff,
  }) async {
    final applied = [
      for (final pid in presetIds) AppliedPresetRef(presetId: pid),
    ];

    final res = await _instances.create(
      name: name,
      optionPresetId: optionPresetId,
      appliedPresets: applied,
      seedMode: seedMode,
    );
    return _refreshWhenOk(res);
  }

  /// 인스턴스 삭제 → 목록 갱신.
  Future<void> deleteInstance(String instanceId) async {
    await _instances.delete(instanceId);
    await refresh();
  }

  /// 인스턴스 복제 → 목록 갱신.
  ///
  /// - UI에서 지역화된 접미사(예: `" (copy)"`)를 넘겨준다.
  Future<void> duplicateInstance({
    required String sourceId,
    required String duplicateSuffix,
  }) async {
    await _instances.clone(
      sourceId: sourceId,
      duplicateSuffix: duplicateSuffix,
    );
    await refresh();
  }

  /// **경량** 활성 모드 수 반환.
  ///
  /// - 캐시(현재 상태)에서 `InstanceView.enabledCount`를 우선 사용
  /// - 없으면 Service로 단건 View 조회하여 반환
  Future<int> getEnabledCount(String instanceId) async {
    final cached = state.valueOrNull;
    if (cached != null) {
      final v = cached.firstWhere(
            (e) => e.id == instanceId,
        orElse: () => InstanceView.empty,
      );
      if (v.id.isNotEmpty) return v.enabledCount;
    }

    final view = await _instances.getViewById(instanceId);
    return view?.enabledCount ?? 0;
  }

  /// (선택) 캐시에서 단건 View 조회. 없으면 Service 조회.
  Future<InstanceView?> getByIdFast(String id) async {
    final cached = state.valueOrNull;
    if (cached != null) {
      final v = cached.firstWhere(
            (e) => e.id == id,
        orElse: () => InstanceView.empty,
      );
      if (v.id.isNotEmpty) return v;
    }
    return _instances.getViewById(id);
  }

  /// 드래그로 정한 순서를 영구 저장 → 성공 시 목록 갱신
  Future<Result<void>> reorderInstances(List<String> orderedIds) async {
    final res = await _instances.reorderInstances(orderedIds); // Service 호출
    return _refreshWhenOk(res); // ok면 refresh
  }
}

/// 인스턴스 **뷰 목록** Provider.
/// - 상태: `AsyncValue<List<InstanceView>>`
final instancesControllerProvider =
AutoDisposeAsyncNotifierProvider<InstancesController, List<InstanceView>>(
  InstancesController.new,
);

/// 목록에서 단건 **InstanceView** 를 빠르게 얻는 헬퍼 Provider.
final instanceViewByIdProvider =
Provider.family<InstanceView?, String>((ref, id) {
  final asyncList = ref.watch(instancesControllerProvider);
  return asyncList.maybeWhen(
    data: (list) => list.firstWhere(
          (e) => e.id == id,
      orElse: () => InstanceView.empty,
    ),
    orElse: () => null,
  )?.let((e) => e.id.isEmpty ? null : e);
});

/// “활성 모드 수” FutureProvider(경량 추정).
final instanceEnabledCountProvider =
FutureProvider.family<int, String>((ref, instanceId) async {
  final ctrl = ref.read(instancesControllerProvider.notifier);
  return ctrl.getEnabledCount(instanceId);
});

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
