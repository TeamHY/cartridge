import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/core/utils/clipboard_share.dart';
import 'package:cartridge/features/cartridge/mod_presets/application/mod_preset_detail_controller.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';

/// 페이지 전용(UI 메타) 상태.
/// - 검색어, 선택 상태, 이름 편집 중 여부 등 화면 전용 상태 전담
class ModPresetDetailUiState {
  final bool editingName;
  final String search;
  final Map<String, bool> selections;

  const ModPresetDetailUiState({
    required this.editingName,
    required this.search,
    required this.selections,
  });

  const ModPresetDetailUiState.initial()
      : editingName = false,
        search = '',
        selections = const {};

  ModPresetDetailUiState copyWith({
    bool? editingName,
    String? search,
    Map<String, bool>? selections,
  }) {
    return ModPresetDetailUiState(
      editingName: editingName ?? this.editingName,
      search: search ?? this.search,
      selections: selections ?? this.selections,
    );
  }
}

/// # ModPresetDetailPageController
///
/// 프리셋 상세의 **Presentation 컨트롤러**입니다.
/// - family(arg=presetId)
/// - 책임:
///   - 검색/선택/이름편집 플래그 관리(화면 전용 상태)
///   - Application 컨트롤러와 협업해 정렬/이름변경/토글/배치/삭제 호출
///   - 표시용 행에 대한 클립보드 복사 유틸
class ModPresetDetailPageController
    extends AutoDisposeFamilyNotifier<ModPresetDetailUiState, String> {
  late String _presetId;

  @override
  ModPresetDetailUiState build(String argPresetId) {
    _presetId = argPresetId;
    // Application 상태 구독 → 뷰 갱신에 맞춰 presentation도 re-build
    ref.watch(modPresetDetailControllerProvider(_presetId));
    return const ModPresetDetailUiState.initial();
  }

  // ── UI 메타 상태 조작 ───────────────────────────────────────────────────────────

  void startEditName() => state = state.copyWith(editingName: true);
  void cancelEditName() => state = state.copyWith(editingName: false);
  void setSearch(String q) => state = state.copyWith(search: q);
  bool isSelected(String rowKey) => state.selections[rowKey] == true;
  Iterable<String> get _selectedRowKeys =>
      state.selections.entries.where((e) => e.value).map((e) => e.key);

  void setRowSelected(String rowKey, bool v) {
    final m = Map<String, bool>.from(state.selections)..[rowKey] = v;
    state = state.copyWith(selections: m);
  }

  // ── Application 유스케이스 호출 래퍼 ───────────────────────────────────────────────────────────

  Future<void> saveName(String name) async {
    await ref
        .read(modPresetDetailControllerProvider(_presetId).notifier)
        .rename(name);
    state = state.copyWith(editingName: false);
  }


  Future<void> toggleFavorite(String rowKey) async {
    final map = ref.read(modPresetItemsByKeyProvider(_presetId));
    final hit = map[rowKey];
    if (hit == null) return;
    await ref
        .read(modPresetDetailControllerProvider(_presetId).notifier)
        .toggleFavorite(hit);
  }

  Future<void> setEnabled(String rowKey, bool enabled) async {
    final map = ref.read(modPresetItemsByKeyProvider(_presetId));
    final hit = map[rowKey];
    if (hit == null) return;
    await ref.read(modPresetDetailControllerProvider(_presetId).notifier)
        .setEnabled(hit, enabled);
  }

  Future<void> removeByKey(String rowKey) async {
    final map = ref.read(modPresetItemsByKeyProvider(_presetId));
    final hit = map[rowKey];
    if (hit == null) return;

    await ref.read(modPresetDetailControllerProvider(_presetId).notifier)
        .removeItem(hit);

    final sel = Map<String, bool>.from(state.selections)..remove(rowKey);
    state = state.copyWith(selections: sel);
  }

  Future<void> favoriteSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;

    final map   = ref.read(modPresetItemsByKeyProvider(_presetId));
    final items = keys.map((k) => map[k]).whereType<ModView>();

    await ref.read(modPresetDetailControllerProvider(_presetId).notifier)
        .bulkFavorite(items, true);
  }

  Future<void> unfavoriteSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;

    final map   = ref.read(modPresetItemsByKeyProvider(_presetId));
    final items = keys.map((k) => map[k]).whereType<ModView>();

    await ref.read(modPresetDetailControllerProvider(_presetId).notifier)
        .bulkFavorite(items, false);
  }

  Future<void> enableSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;

    final map   = ref.read(modPresetItemsByKeyProvider(_presetId));
    final items = keys.map((k) => map[k]).whereType<ModView>();

    await ref.read(modPresetDetailControllerProvider(_presetId).notifier)
        .bulkEnable(items, true);
  }

  Future<void> disableSelected() async {
    final keys = _selectedRowKeys.toSet();
    if (keys.isEmpty) return;

    final map   = ref.read(modPresetItemsByKeyProvider(_presetId));
    final items = keys.map((k) => map[k]).whereType<ModView>();

    await ref.read(modPresetDetailControllerProvider(_presetId).notifier)
        .bulkEnable(items, false);
  }

  Future<void> refreshFromStore() async {
    await ref
        .read(modPresetDetailControllerProvider(_presetId).notifier)
        .refreshInstalled();
  }

  Future<void> deletePreset() async {
    await ref
        .read(modPresetDetailControllerProvider(_presetId).notifier)
        .deletePreset();
  }

  // ── 공유(클립보드) ───────────────────────────────────────────────────────────

  /// 선택된 행의 이름을 **plain + HTML 링크 리스트**로 복사.
  /// - HTML은 `<ul><li>` 형태, 링크는 `steam://` 우선 URL 사용
  Future<int> copySelectedNamesRich() async {
    final rows = ref.read(modPresetDetailControllerProvider(_presetId));
    final selected = _selectedRowKeys.toSet();
    final picked = rows.value?.items.where((r) => selected.contains(r.id)).toList(growable: false);

    if (picked!.isEmpty) return 0;

    final items = [
      for (final r in picked)
        ShareItem(
          name: r.displayName,
          workshopId: r.modId,
        ),
    ];

    try {
      await ClipboardShare.copyNamesRich(items);
      return items.length; // 성공: 개수 반환
    } catch (_) {
      return -1;           // 실패: -1
    }
  }

  Future<int> copySelectedNamesPlain() async {
    final rows = ref.read(modPresetDetailControllerProvider(_presetId));
    final selected = _selectedRowKeys.toSet();
    final picked = rows.value?.items.where((r) => selected.contains(r.id)).toList(growable: false) ?? const [];
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
    final rows = ref.read(modPresetDetailControllerProvider(_presetId));
    final selected = _selectedRowKeys.toSet();
    final picked = rows.value?.items.where((r) => selected.contains(r.id)).toList(growable: false) ?? const [];
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

/// Presentation 컨트롤러 Provider (family: presetId)
final modPresetDetailPageControllerProvider =
AutoDisposeNotifierProviderFamily<ModPresetDetailPageController, ModPresetDetailUiState, String>(
  ModPresetDetailPageController.new,
);

/// # modPresetVisibleResolvedProvider
///
/// 표시용 행(Visible rows) **파생 Provider**.
/// - Application의 `ModPresetView.items`(이미 Service/Projector가 합성/정렬 반영)를
///   가져와 **검색 필터만** 적용해 반환.
/// - 정렬은 Application 컨트롤러에서 즉시 재정렬 + 저장소 저장으로 처리되므로
///   여기서는 정렬을 수행하지 않습니다.
final modPresetVisibleResolvedProvider =
AutoDisposeProvider.family<List<ModView>, String>((ref, presetId) {
  final app = ref.watch(modPresetDetailControllerProvider(presetId));
  final ui  = ref.watch(modPresetDetailPageControllerProvider(presetId));

  return app.maybeWhen(
    data: (view) {
      final q = ui.search.trim().toLowerCase();
      final base = view.items;
      if (q.isEmpty) return base;
      return base
          .where((v) =>
      v.displayName.toLowerCase().contains(q) ||
          v.installedRef!.metadata.version.toLowerCase().contains(q))
          .toList(growable: false);
    },
    orElse: () => const <ModView>[],
  );
});
