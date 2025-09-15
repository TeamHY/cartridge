import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/utils/clipboard_share.dart';
import 'package:cartridge/features/cartridge/instances/application/instance_detail_controller.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_image.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/applied_preset_ref.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/isaac/mod/domain/models/mod_view.dart';

/// 페이지 전용(UI 메타) 상태.
class InstanceDetailUiState {
  final bool editingName;

  /// 헤더/썸네일에 쓰일 이미지 (nullable: loading 전/스켈레톤)
  final InstanceImage? image;

  /// 헤더 타이틀 편집에 쓰일 현재 표시 이름(UI 캐시)
  final String displayName;

  final String search;
  final Map<String, bool> selections;

  /// 프리셋 필터 UI 상태
  final bool excludeMode;                  // "프리셋 제외" 모드
  final Set<String> selectedPresetFilterIds; // 선택 프리셋 집합(전체=모든 프리셋 id)

  const InstanceDetailUiState({
    required this.editingName,
    required this.image,
    required this.displayName,
    required this.search,
    required this.selections,
    this.excludeMode = false,
    this.selectedPresetFilterIds = const {},
  });

  /// 초기 진입: image = null 로 두어 스켈레톤이 보이도록
  InstanceDetailUiState.initial()
      : editingName = false,
        image = null,
        displayName = '',
        search = '',
        selections = const {},
        excludeMode = false,
        selectedPresetFilterIds = const {};

  /// image는 별도 세터로만 변경(=null 지정 가능)
  InstanceDetailUiState copyWith({
    bool? editingName,
    String? search,
    String? displayName,
    Map<String, bool>? selections,
    bool? excludeMode,
    Set<String>? selectedPresetFilterIds,
  }) {
    return InstanceDetailUiState(
      editingName: editingName ?? this.editingName,
      image: image, // 그대로 유지
      displayName: displayName ?? this.displayName,
      search: search ?? this.search,
      selections: selections ?? this.selections,
      excludeMode: excludeMode ?? this.excludeMode,
      selectedPresetFilterIds:
      selectedPresetFilterIds ?? this.selectedPresetFilterIds,
    );
  }

  /// image만 교체(=null 허용)
  InstanceDetailUiState withImage(InstanceImage? next) {
    return InstanceDetailUiState(
      editingName: editingName,
      image: next,
      displayName: displayName,
      search: search,
      selections: selections,
      excludeMode: excludeMode,
      selectedPresetFilterIds: selectedPresetFilterIds,
    );
  }
}

/// 인스턴스 상세의 Presentation 컨트롤러.
class InstanceDetailPageController
    extends AutoDisposeFamilyNotifier<InstanceDetailUiState, String> {
  late String _instanceId;

  @override
  InstanceDetailUiState build(String argInstanceId) {
    _instanceId = argInstanceId;
    ref.watch(instanceDetailControllerProvider(_instanceId)); // 앱 상태 구독
    return InstanceDetailUiState.initial();
  }

  // ── UI 메타 상태 ───────────────────────────────────────────────────────────
  void startEditName() => state = state.copyWith(editingName: true);
  void cancelEditName() => state = state.copyWith(editingName: false);
  void setSearch(String q) => state = state.copyWith(search: q);
  void setDisplayName(String name) => state = state.copyWith(displayName: name);
  void setUiImage(InstanceImage? img) => state = state.withImage(img);

  /// 앱 상태로부터 UI 캐시를 동기화. image는 null 가능.
  void hydrate({required String name, InstanceImage? image}) {
    state = state.copyWith(displayName: name).withImage(image);
  }

  bool isSelected(String rowKey) => state.selections[rowKey] == true;
  bool get anySelected => state.selections.values.any((v) => v);
  Iterable<String> get _selectedRowKeys =>
      state.selections.entries.where((e) => e.value).map((e) => e.key);

  void setRowSelected(String rowKey, bool v) {
    final m = Map<String, bool>.from(state.selections)..[rowKey] = v;
    state = state.copyWith(selections: m);
  }

  // ── Application 위임 ───────────────────────────────────────────────────────────
  Future<void> saveName(String name) async {
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).rename(name);
    state = state.copyWith(editingName: false, displayName: name);
  }


  Future<void> toggleFavorite(String rowKey) async {
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final hit = map[rowKey];
    if (hit == null) return;
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).toggleFavorite(hit);
  }

  Future<void> setEnabled(String rowKey, bool enabled) async {
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final hit = map[rowKey];
    if (hit == null) return;
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).setEnabled(hit, enabled);
  }

  Future<void> removeByKey(String rowKey) async {
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final hit = map[rowKey];
    if (hit == null) return;
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).removeItem(hit);
    final sel = Map<String, bool>.from(state.selections)..remove(rowKey);
    state = state.copyWith(selections: sel);
  }

  Future<void> favoriteSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final items = keys.map((k) => map[k]).whereType<ModView>();
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).bulkFavorite(items, true);
  }

  Future<void> unfavoriteSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final items = keys.map((k) => map[k]).whereType<ModView>();
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).bulkFavorite(items, false);
  }

  Future<void> enableSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final items = keys.map((k) => map[k]).whereType<ModView>();
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).bulkEnable(items, true);
  }

  Future<void> disableSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;
    final map = ref.read(instanceItemsByKeyProvider(_instanceId));
    final items = keys.map((k) => map[k]).whereType<ModView>();
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).bulkEnable(items, false);
  }

  Future<void> refreshFromStore() async {
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).refreshInstalled();
  }

  Future<void> deleteInstance() async {
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier).deleteInstance();
  }

  // ── Instance attributes (option preset, applied mod presets) ───────────────────────────────────────────────────────────
  Future<void> setOptionPreset(String? optionPresetId) async {
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier)
        .setOptionPreset(optionPresetId);
  }

  Future<void> setPresetIds(List<AppliedPresetRef> ids) async {
    await ref.read(instanceDetailControllerProvider(_instanceId).notifier)
        .setPresetIds(ids);
  }

  /// 선택된 행 이름을 plain + HTML 링크로 복사
  Future<int> copySelectedNamesRich() async {
    final rows = ref.read(instanceDetailControllerProvider(_instanceId));
    final selected = _selectedRowKeys.toSet();
    final picked =
    rows.value?.items.where((r) => selected.contains(r.id)).toList(growable: false);

    if (picked == null || picked.isEmpty) return 0;

    final items = [
      for (final r in picked)
        ShareItem(
          name: r.displayName,
          workshopId: r.modId,
        ),
    ];

    try {
      await ClipboardShare.copyNamesRich(items);
      return items.length;
    } catch (_) {
      return -1;
    }
  }

  Future<int> copySelectedNamesPlain() async {
    final rows = ref.read(instanceDetailControllerProvider(_instanceId));
    final selected = _selectedRowKeys.toSet();
    final picked =
        rows.value?.items.where((r) => selected.contains(r.id)).toList(growable: false) ??
            const [];
    if (picked.isEmpty) return 0;

    final items = [
      for (final r in picked)
        ShareItem(
          name: r.displayName,
          workshopId: (r.installedRef?.metadata.id ?? '').trim().isEmpty
              ? null
              : r.installedRef!.metadata.id.trim(),
        ),
    ];
    try {
      await ClipboardShare.copyNamesPlain(items);
      return items.length;
    } catch (_) {
      return -1;
    }
  }

  Future<int> copySelectedNamesMarkdown() async {
    final rows = ref.read(instanceDetailControllerProvider(_instanceId));
    final selected = _selectedRowKeys.toSet();
    final picked =
        rows.value?.items.where((r) => selected.contains(r.id)).toList(growable: false) ??
            const [];
    if (picked.isEmpty) return 0;

    final items = [
      for (final r in picked)
        ShareItem(
          name: r.displayName,
          workshopId: (r.installedRef?.metadata.id ?? '').trim().isEmpty
              ? null
              : r.installedRef!.metadata.id.trim(),
        ),
    ];
    try {
      await ClipboardShare.copyNamesMarkdown(items);
      return items.length;
    } catch (_) {
      return -1;
    }
  }
}

final instanceDetailPageControllerProvider =
AutoDisposeNotifierProviderFamily<InstanceDetailPageController,
    InstanceDetailUiState, String>(
  InstanceDetailPageController.new,
);

/// 가시 목록 필터링
final instanceVisibleResolvedProvider =
AutoDisposeProvider.family<List<ModView>, String>((ref, instanceId) {
  final app = ref.watch(instanceDetailControllerProvider(instanceId));

  return app.maybeWhen(
    data: (view) => view.items, // 검색/필터/정렬은 UTTable이 담당
    orElse: () => const <ModView>[],
  );
});
