import 'package:cartridge/features/cartridge/option_presets/application/option_presets_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/features/cartridge/instances/application/instances_controller.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_view.dart';


/// 인스턴스 목록 화면 전용 프레젠테이션 상태.
/// - 앱 전역 상태(목록)는 application controller가 담당
/// - 여기서는 검색어 등 **UI 메타 상태만** 보관/관리합니다.
final instancesQueryProvider = StateProvider<String>((ref) => '');

/// 검색어가 반영된 **필터링 결과**를 AsyncValue로 제공합니다.
/// - 정렬은 InstancesService 쪽 정책을 따르고, 여기서는 필터만 수행합니다.
final filteredInstancesProvider =
Provider<AsyncValue<List<InstanceView>>>((ref) {
  final listAsync = ref.watch(instancesControllerProvider);
  final q = ref.watch(instancesQueryProvider).trim().toLowerCase();

  return listAsync.whenData((list) {
    if (q.isEmpty) return list;
    return list
        .where((it) => it.name.toLowerCase().contains(q))
        .toList(growable: false);
  });
});

final useRepentogonByPresetIdProvider =
Provider.family<bool, String?>((ref, presetId) {
  if (presetId == null || presetId.isEmpty) return false;
  // 필요한 필드만 구독해 리빌드 최소화
  return ref.watch(
    optionPresetByIdProvider(presetId).select((p) => p?.useRepentogon ?? false),
  );
});

/// 정렬 모드 on/off
final instancesReorderModeProvider = StateProvider<bool>((ref) => false);

/// 순서 변경됨(dirty) 플래그
final instancesReorderDirtyProvider = StateProvider<bool>((ref) => false);

/// 정렬 작업 중인 **Instance ID 순서**를 보관하는 Notifier
class InstancesWorkingOrder extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// 현재 화면의 리스트로 초기화(정렬 시작 시 호출)
  void syncFrom(List<InstanceView> list) {
    state = list.map((e) => e.id).toList(growable: false);
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

final instancesWorkingOrderProvider =
NotifierProvider<InstancesWorkingOrder, List<String>>(
    InstancesWorkingOrder.new);

/// (도우미) 정렬 모드일 때 working order를 적용한 **UI용 리스트**
final orderedInstancesForUiProvider =
Provider<AsyncValue<List<InstanceView>>>((ref) {
  final baseAsync = ref.watch(filteredInstancesProvider);
  final inReorder = ref.watch(instancesReorderModeProvider);
  final order = ref.watch(instancesWorkingOrderProvider);

  return baseAsync.whenData((base) {
    if (!inReorder || order.isEmpty) return base;

    // 현재 리스트를 id→view 맵으로
    final map = {for (final v in base) v.id: v};
    final out = <InstanceView>[];

    // working order 순서대로 채우고, 혹시 빠진 항목이 있으면 뒤에 덧붙임(방어적)
    for (final id in order) {
      final v = map.remove(id);
      if (v != null) out.add(v);
    }
    if (map.isNotEmpty) out.addAll(map.values);
    return out;
  });
});