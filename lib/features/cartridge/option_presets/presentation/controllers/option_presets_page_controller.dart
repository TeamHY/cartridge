import 'package:cartridge/app/presentation/widgets/list_page/reorder_helpers.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/features/cartridge/setting/application/app_setting_controller.dart';
import 'package:cartridge/features/isaac/options/application/isaac_options_ini_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';

/// 검색 쿼리(화면 전용)
final optionPresetsQueryProvider = StateProvider<String>((_) => '');

/// 검색 적용 뷰 모델(가벼운 필터만)
final filteredOptionPresetsProvider =
Provider<AsyncValue<List<OptionPresetView>>>((ref) {
  final listAsync = ref.watch(optionPresetsControllerProvider);
  final query = ref.watch(optionPresetsQueryProvider).trim().toLowerCase();

  return listAsync.whenData((list) {
    if (query.isEmpty) return list;
    return list
        .where((p) => p.name.toLowerCase().contains(query))
        .toList(growable: false);
  });
});

/// 정렬 모드 on/off
final optionPresetsReorderModeProvider = StateProvider<bool>((ref) => false);

/// 순서 변경됨(dirty) 플래그
final optionPresetsReorderDirtyProvider = StateProvider<bool>((ref) => false);

/// 정렬 작업 중인 **Option preset ID 순서**를 보관하는 Notifier
class OptionPresetsWorkingOrder extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  /// 현재 화면의 리스트로 초기화(정렬 시작 시 호출)
  void syncFrom(List<OptionPresetView> list) {
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

final optionPresetsWorkingOrderProvider =
NotifierProvider<OptionPresetsWorkingOrder, List<String>>(
    OptionPresetsWorkingOrder.new);

/// (도우미) 정렬 모드일 때 working order를 적용한 **UI용 리스트**
final orderedOptionPresetsForUiProvider =
Provider<AsyncValue<List<OptionPresetView>>>((ref) {
  final baseAsync = ref.watch(filteredOptionPresetsProvider);
  final inReorder = ref.watch(optionPresetsReorderModeProvider);
  final order = ref.watch(optionPresetsWorkingOrderProvider);

  return baseAsync.whenData((base) {
    if (!inReorder || order.isEmpty) return base;
    return applyWorkingOrder<OptionPresetView>(base, order, (e) => e.id);
  });
});

// 현재 PC의 options.ini로부터 초기 OptionPresetView 생성
final optionPresetInitialFromCurrentProvider =
FutureProvider<OptionPresetView?>((ref) async {
  // 1) 앱 설정을 읽어서 options.ini 경로 결정(수동 > 자동탐지)
  final s = await ref.read(appSettingControllerProvider.future);

  String? iniPath;
  if (!s.useAutoDetectOptionsIni && s.optionsIniPath.trim().isNotEmpty) {
    iniPath = s.optionsIniPath.trim();
  } else {
    final env = ref.read(isaacEnvironmentServiceProvider);
    iniPath = await env.detectOptionsIniPathAuto();
  }
  if (iniPath == null || iniPath.isEmpty) return null;

  // 2) options.ini 읽기
  final svc = IsaacOptionsIniService();
  final opts = await svc.read(optionsIniPath: iniPath);

  // 3) 읽은 값을 그대로 초기 프리셋에 매핑(이름은 비워두면 다이얼로그 placeholder 사용)
  return OptionPresetView(
    id: '',
    name: '',
    windowWidth: opts.windowWidth,
    windowHeight: opts.windowHeight,
    windowPosX: opts.windowPosX,
    windowPosY: opts.windowPosY,
    fullscreen: opts.fullscreen,
    gamma: opts.gamma,
    enableDebugConsole: opts.enableDebugConsole,
    pauseOnFocusLost: opts.pauseOnFocusLost,
    mouseControl: opts.mouseControl,
    // useRepentogon은 다이얼로그에서 토글 제공(설치여부는 별도 판단)
  );
});