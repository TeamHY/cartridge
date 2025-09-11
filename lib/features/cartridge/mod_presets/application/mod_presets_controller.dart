import 'package:cartridge/core/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/mod_presets_service.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset_view.dart';
import 'package:cartridge/features/isaac/mod/domain/models/seed_mode.dart';

/// # ModPresetsController (Application)
/// - 화면 비의존적인 비즈니스 로직 컨트롤러
/// - 상태: `AsyncValue<List<ModPresetView>>`
/// - 책임: 목록 로드/새로고침, 생성/복제/삭제
/// - 설치 목록/경로 해석은 Service 내부(IsaacEnvironmentService)에서 처리됨
class ModPresetsController extends AutoDisposeAsyncNotifier<List<ModPresetView>> {
  ModPresetsService get _presets => ref.read(modPresetsServiceProvider);

  @override
  Future<List<ModPresetView>> build() async {
    return _presets.listAllViews();
  }

  /// 목록 강제 새로고침
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _presets.listAllViews());
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

  Future<Result<ModPresetView>> create({
    required String name,
    SeedMode seedMode = SeedMode.allOff,
  }) async {
    final res = await _presets.create(
      name: name,
      seedMode: seedMode,
    );
    return _refreshWhenOk(res);
  }

  /// 프리셋 복제
  Future<Result<ModPresetView>> clone(
      String sourceId, {
        required String duplicateSuffix,
      }) async {
    final res = await _presets.clone(
      sourceId: sourceId,
      duplicateSuffix: duplicateSuffix,
    );
    return _refreshWhenOk(res);
  }

  /// 프리셋 삭제
  Future<Result<void>> remove(String presetId) async {
    final res = await _presets.delete(presetId);
    return _refreshWhenOk(res);
  }

  /// 드래그로 정한 순서를 영구 저장 → 성공 시 목록 갱신
  Future<Result<void>> reorderModPresets(List<String> orderedIds) async {
    final res = await _presets.reorderModPresets(orderedIds); // Service 호출
    return _refreshWhenOk(res); // ok면 refresh
  }
}

/// 목록 Provider
final modPresetsControllerProvider =
AutoDisposeAsyncNotifierProvider<ModPresetsController, List<ModPresetView>>(
  ModPresetsController.new,
);
