import 'package:cartridge/app/presentation/widgets/list_page/reorder_helpers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/features/cartridge/mod_presets/application/mod_presets_controller.dart';
import 'package:cartridge/features/cartridge/mod_presets/domain/models/mod_preset_view.dart';

/// 검색 쿼리 상태 (페이지 전용)
final modPresetsQueryProvider = AutoDisposeStateProvider<String>((ref) => '');

/// 검색이 적용된 프리셋 목록
/// - 정렬은 Service(listAll) 규칙을 유지, 여기서는 **필터만** 수행.
final filteredModPresetsProvider =
AutoDisposeProvider<AsyncValue<List<ModPresetView>>>((ref) {
  final listAsync = ref.watch(modPresetsControllerProvider);
  final query = ref.watch(modPresetsQueryProvider).trim().toLowerCase();

  return listAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where((v) => v.name.toLowerCase().contains(query))
        .toList(growable: false);
  });
});

/// ID 단건 조회 (목록 캐시 기반)
final modPresetByIdProvider =
AutoDisposeProvider.family<ModPresetView?, String>((ref, id) {
  final asyncList = ref.watch(modPresetsControllerProvider);
  return asyncList.maybeWhen(
    data: (list) {
      for (final v in list) {
        if (v.key == id) return v;
      }
      return null;
    },
    orElse: () => null,
  );
});

/// 정렬 모드 on/off
final modPresetsReorderModeProvider = StateProvider<bool>((ref) => false);

/// 순서 변경됨(dirty) 플래그
final modPresetsReorderDirtyProvider = StateProvider<bool>((ref) => false);

/// 정렬 작업 중인 **Mod preset ID 순서**를 보관하는 Notifier
class ModPresetsWorkingOrder extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// 현재 화면의 리스트로 초기화(정렬 시작 시 호출)
  void syncFrom(List<ModPresetView> list) {
    state = list.map((e) => e.key).toList(growable: false);
  }

  /// 드래그 결과 반영
  void move(int oldIndex, int newIndex) {
    final xs = [...state];
    final item = xs.removeAt(oldIndex);
    xs.insert(newIndex, item);
    state = xs;
  }


  void setAll(List<String> ids) {
    state = List.unmodifiable(ids);
  }

  /// 취소 시 초기화
  void reset() => state = const [];
}

final modPresetsWorkingOrderProvider =
NotifierProvider<ModPresetsWorkingOrder, List<String>>(
    ModPresetsWorkingOrder.new);

/// (도우미) 정렬 모드일 때 working order를 적용한 **UI용 리스트**
final orderedModPresetsForUiProvider =
Provider<AsyncValue<List<ModPresetView>>>((ref) {
  final baseAsync = ref.watch(filteredModPresetsProvider);
  final inReorder = ref.watch(modPresetsReorderModeProvider);
  final order = ref.watch(modPresetsWorkingOrderProvider);

  return baseAsync.whenData((base) {
    if (!inReorder || order.isEmpty) return base;
    return applyWorkingOrder<ModPresetView>(base, order, (e) => e.key);
  });
});