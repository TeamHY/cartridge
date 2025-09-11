import 'package:cartridge/core/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';

class OptionPresetsController extends AsyncNotifier<List<OptionPresetView>> {
  OptionPresetsService get _svc => ref.read(optionPresetsServiceProvider);

  @override
  Future<List<OptionPresetView>> build() async {
    return _svc.listAllViews();
  }

  /// 강제 새로고침
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _svc.listAllViews());
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

  Future<void> create(OptionPresetView v) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _svc.createView(
        name: v.name,
        windowWidth: v.windowWidth,
        windowHeight: v.windowHeight,
        windowPosX: v.windowPosX,
        windowPosY: v.windowPosY,
        fullscreen: v.fullscreen,
        gamma: v.gamma,
        enableDebugConsole: v.enableDebugConsole,
        pauseOnFocusLost: v.pauseOnFocusLost,
        mouseControl: v.mouseControl,
        useRepentogon: v.useRepentogon,
      );
      return _svc.listAllViews();
    });
  }

  Future<void> fetch(OptionPresetView v) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _svc.updateView(
        v.id,
        name: v.name,
        windowWidth: v.windowWidth,
        windowHeight: v.windowHeight,
        windowPosX: v.windowPosX,
        windowPosY: v.windowPosY,
        fullscreen: v.fullscreen,
        gamma: v.gamma,
        enableDebugConsole: v.enableDebugConsole,
        pauseOnFocusLost: v.pauseOnFocusLost,
        mouseControl: v.mouseControl,
        useRepentogon: v.useRepentogon,
      );
      return _svc.listAllViews();
    });
  }

  Future<void> remove(String id) async {
    await _svc.deleteView(id);
    await refresh();
  }

  Future<Result<OptionPresetView>> clone(String sourceId, String duplicateSuffix) async {
    final res = await _svc.cloneView(sourceId, duplicateSuffix: duplicateSuffix);
    return await res.map(
      ok: (r) async { await refresh(); return r; },
      notFound: (r) async => r,
      invalid: (r) async => r,
      conflict: (r) async => r,
      failure: (r) async => r,
    );
  }

  Future<bool> isRepentogonInstalled() async {
    return await ref.read(repentogonInstalledProvider.future);
  }

  /// 드래그로 정한 순서를 영구 저장 → 성공 시 목록 갱신
  Future<Result<void>> reorderOptionPresets(List<String> orderedIds) async {
    final res = await _svc.reorderOptionPresets(orderedIds); // Service 호출
    return _refreshWhenOk(res); // ok면 refresh
  }
}

/// 단건 조회(캐시 기반)
final optionPresetByIdProvider =
Provider.family<OptionPresetView?, String>((ref, id) {
  final list = ref.watch(optionPresetsControllerProvider).valueOrNull;
  if (list == null) return null;
  for (final p in list) {
    if (p.id == id) return p;
  }
  return null;
});
