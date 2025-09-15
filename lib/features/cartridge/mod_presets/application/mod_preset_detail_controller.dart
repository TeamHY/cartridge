import 'package:cartridge/core/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/mod_presets/application/mod_presets_controller.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/mod_presets_service.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset_view.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

/// # ModPresetDetailController
///
/// 프리셋 상세 화면의 **Application 컨트롤러**.
///
/// - 상태 타입은 항상 `ModPresetView`(뷰 모델)만 노출합니다.
/// - IsaacEnvironment(설치 경로/설치 목록 해석)는 **Service 계층**에서만 다룹니다
///   → 컨트롤러는 `IsaacEnvironmentService`를 직접 참조하지 않습니다.
/// - 정렬(Sort)은 **즉시 화면(View) 재정렬**하고, **정렬 기준은 저장소(Repository)에 영구 저장**합니다.
///
/// 정렬 버튼 동작:
/// 1) 현재 `items`를 즉시 재정렬해 화면에 반영
/// 2) 같은 기준을 Service를 통해 저장소에 저장(영구화)
class ModPresetDetailController
    extends AutoDisposeFamilyAsyncNotifier<ModPresetView, String> {
  ModPresetsService get _presets => ref.read(modPresetsServiceProvider);
  late String _presetId;

  @override
  Future<ModPresetView> build(String argPresetId) async {
    _presetId = argPresetId;

    final res = await _presets.getViewById(presetId: _presetId);

    return res.when(
      ok: (data, code, ctx) {
        return data ?? (throw StateError('Empty ModPresetView: $_presetId'));
      },
      notFound: (code, ctx) => throw StateError('ModPreset not found: $_presetId'),
      invalid: (violations, code, ctx) =>
      throw StateError('Invalid ModPreset($_presetId): $violations'),
      conflict: (code, ctx) =>
      throw StateError('Conflict while loading ModPreset: $_presetId'),
      failure: (code, error, ctx) =>
      throw StateError('Failed to load ModPreset($_presetId): $error'),
    );
  }

  // ── Internals(내부 유틸) ───────────────────────────────────────────────────────────

  /// Service에서 최신 View를 받아와 **현재 정렬 기준**으로 재정렬 후 상태 반영.
  Future<void> _reload() async {
    final res    = await _presets.getViewById(presetId: _presetId);
    final fresh  = res.maybeWhen(ok: (data, _, __) => data, orElse: () => null);
    if (fresh == null) return;
    state = AsyncData(fresh);
    _touchList();
  }

  Future<void> refreshInstalled() async {
    await _reload();
  }

  // ── 편집/상호작용(모두 Service 경유) ───────────────────────────────────────────────────────────

  /// 프리셋 이름 변경 후, 최신 View를 현재 정렬 기준으로 재적용.
  Future<void> rename(String name) async {
    await _presets.rename(_presetId, name);
    await _reload();
  }

  /// 즐겨찾기 토글 (rowKey = ModView.key)
  Future<void> toggleFavorite(ModView item) async {
    await setFavorite(item, !item.favorite);
  }

  /// 활성/비활성 토글 (rowKey = ModView.key)
  Future<void> toggleEnabled(ModView item) async {
    await setEnabled(item, !item.enabled);
  }

  /// 즐겨찾기 설정 (rowKey = ModView.key)
  Future<void> setFavorite(ModView item, bool favorite) async {
    await _presets.setItemState(
      presetId: _presetId,
      item    : item,
      favorite : favorite,
    );
    await _reload();
  }

  /// 활성/비활성 설정 (rowKey = ModView.key)
  Future<void> setEnabled(ModView item, bool enabled) async {
    await _presets.setItemState(
      presetId: _presetId,
      item    : item,
      enabled : enabled,
    );
    await _reload();
  }

  /// 항목 제거
  Future<void> removeItem(ModView item) async {
    await _presets.deleteItem(
      presetId: _presetId,
      itemId    : item.id,
    );
    await _reload();
  }

  /// 배치: 즐겨찾기 일괄 설정
  Future<void> bulkFavorite(Iterable<ModView> items, bool fav) async {
    await _presets.bulkSetItemState(
      presetId: _presetId,
      items   : items,
      favorite: fav,
    );
    await _reload();
  }

  /// 배치: 활성 일괄 설정
  Future<void> bulkEnable(Iterable<ModView> items, bool enabled) async {
    await _presets.bulkSetItemState(
      presetId: _presetId,
      items   : items,
      enabled : enabled,
    );
    await _reload();
  }

  /// 프리셋 삭제(라우팅은 호출자에서 처리).
  Future<void> deletePreset() async {
    await _presets.delete(_presetId);
    _touchList();
  }

  void _touchList() => ref.invalidate(modPresetsControllerProvider);
}

/// Application 컨트롤러 Provider (family: presetId)
/// - 상태 타입: `ModPresetView`
/// - 환경/설치 목록은 Service에서 해석
final modPresetDetailControllerProvider =
AutoDisposeAsyncNotifierProviderFamily<ModPresetDetailController, ModPresetView, String>(
  ModPresetDetailController.new,
);

// 키->행 맵 파생
final modPresetItemsByKeyProvider =
AutoDisposeProvider.family<Map<String, ModView>, String>((ref, presetId) {
  final app = ref.watch(modPresetDetailControllerProvider(presetId));
  return app.maybeWhen(
    data: (v) => { for (final m in v.items) m.id: m },
    orElse: () => const {},
  );
});