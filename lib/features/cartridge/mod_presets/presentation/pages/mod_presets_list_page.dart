import 'dart:async';
import 'package:cartridge/core/result.dart';
import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/app/presentation/widgets/list_page/list_page.dart';
import 'package:cartridge/app/presentation/widgets/list_tiles.dart';
import 'package:cartridge/app/presentation/widgets/search_toolbar.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/utils/wiggle.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class ModPresetsListPage extends ConsumerStatefulWidget {
  final void Function(String presetId, String presetName) onSelect;
  const ModPresetsListPage({super.key, required this.onSelect});

  @override
  ConsumerState<ModPresetsListPage> createState() => _ModPresetListPageState();
}

class _ModPresetListPageState extends ConsumerState<ModPresetsListPage> {
  final _searchCtrl   = TextEditingController();
  final _normalScroll = ScrollController();
  final _editScroll   = ScrollController();
  Timer? _debounce;
  late final ReorderAutosave _autosave;
  bool _dragReportedDirty = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));

    _autosave = ReorderAutosave(
      duration: const Duration(minutes: 1),
      isEnabled: () => ref.read(modPresetsReorderModeProvider),
      isDirty:   () => ref.read(modPresetsReorderDirtyProvider),
      getIds:    () => ref.read(modPresetsWorkingOrderProvider),
      commit: (ids) async {
        final loc = AppLocalizations.of(context);
        final result = await ref.read(modPresetsControllerProvider.notifier).reorderModPresets(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, title: loc.common_saved,        content: loc.mod_preset_reorder_saved_desc),
          notFound: (_, __)      async => UiFeedback.warn(context,    title: loc.common_not_found,    content: loc.mod_preset_reorder_not_found_desc),
          invalid:  (_, __, ___) async => UiFeedback.error(context,   title: loc.common_save_fail,    content: loc.mod_preset_reorder_invalid_desc),
          conflict: (_, __)      async => UiFeedback.warn(context, content: loc.mod_preset_reorder_conflict_desc),
          failure:  (_, __, ___) async => UiFeedback.error(context, content: loc.mod_preset_reorder_failure_desc),
        );
      },
      resetAfterSave: () {
        ref.read(modPresetsReorderModeProvider.notifier).state  = false;
        ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
        _dragReportedDirty = false;
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autosave.cancel();
    _normalScroll.dispose();
    _editScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(modPresetsQueryProvider.notifier).state = v.trim();
      if (ref.read(modPresetsReorderModeProvider)) {
        ref.read(modPresetsReorderModeProvider.notifier).state  = false;
        ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
        ref.read(modPresetsWorkingOrderProvider.notifier).reset();
        _dragReportedDirty = false;
        _autosave.cancel();
      }
    });
  }

  Future<void> _goDetail(String id, String name) async {
    widget.onSelect(id, name);
  }

  int _calcCols(double maxW) {
    if (maxW >= AppBreakpoints.lg) return 4;
    if (maxW >= AppBreakpoints.md) return 3;
    return 2;
  }

  Future<void> createFlow() async {
    final res = await showCreatePresetDialog(context);
    if (res == null) return;

    final result = await ref
        .read(modPresetsControllerProvider.notifier)
        .create(name: res.name, seedMode: res.seedMode);

    await result.when(
      ok: (data, _, __) async { if (data != null) await _goDetail(data.key, data.name); },
      notFound: (_, __) async {}, invalid: (_, __, ___) async {},
      conflict: (_, __) async {}, failure:  (_, __, ___) async {},
    );
  }

  void _enterReorder(List<ModPresetView> currentList) {
    final q = ref.read(modPresetsQueryProvider).trim();
    final loc = AppLocalizations.of(context);
    if (q.isNotEmpty) {
      UiFeedback.warn(context, content: loc.mod_preset_reorder_unavailable_desc);
      return;
    }
    ref.read(modPresetsReorderModeProvider.notifier).state  = true;
    ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
    ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(currentList);
    _dragReportedDirty = false;
    _autosave.start();
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    final listAsync = ref.watch(orderedModPresetsForUiProvider);
    final inReorder = ref.watch(modPresetsReorderModeProvider);
    final dirty     = ref.watch(modPresetsReorderDirtyProvider);

    // 상단 툴바(로딩/에러에서도 동일하게 유지)
    Widget toolbar0(List<ModPresetView> currentList) {
      return SearchToolbar(
        controller: _searchCtrl,
        placeholder: loc.mod_preset_search_placeholder,
        onChanged: _onSearchChanged,
        enabled: !inReorder,
        actions: inReorder
            ? [
          Button(
            onPressed: () {
              ref.read(modPresetsReorderModeProvider.notifier).state  = false;
              ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
              ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(currentList);
              _dragReportedDirty = false;
              _autosave.cancel();
            },
            child: Text(loc.common_cancel),
          ),
          Gaps.w8,
          FilledButton(
            onPressed: dirty
                ? () async {
              final ids = ref.read(modPresetsWorkingOrderProvider);
              final result = await ref.read(modPresetsControllerProvider.notifier).reorderModPresets(ids);
              await result.when(
                ok:       (_, __, ___) async {
                  ref.read(modPresetsReorderModeProvider.notifier).state  = false;
                  ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                  UiFeedback.success(context, title: loc.common_saved, content: loc.mod_preset_reorder_saved_desc);
                  _dragReportedDirty = false;
                },
                notFound: (_, __)      async => UiFeedback.warn(context,  title: loc.common_not_found,                   content: loc.mod_preset_reorder_not_found_desc),
                invalid:  (_, __, ___) async => UiFeedback.error(context, title: loc.common_save_fail,   content: loc.mod_preset_reorder_invalid_desc),
                conflict: (_, __)      async => UiFeedback.warn(context, content: loc.mod_preset_reorder_conflict_desc),
                failure:  (_, __, ___) async => UiFeedback.error(context, content: loc.mod_preset_reorder_failure_desc),
              );
              _autosave.cancel();
            }
                : null,
            child: Text(loc.common_save),
          ),
        ]
            : [
          Button(
            onPressed: createFlow,
            child: Row(
              children: [
                const Icon(FluentIcons.add, size: 12),
                Gaps.w4,
                Text(loc.mod_preset_create_button),
              ],
            ),
          ),
          Gaps.w6,
          Button(
            onPressed: () => _enterReorder(currentList),
            child: Row(
              children: [
                const Icon(FluentIcons.edit, size: 12),
                Gaps.w4,
                Text(loc.common_edit),
              ],
            ),
          ),
        ],
      );
    }

    return ScaffoldPage(
      header: const ContentHeaderBar.none(),
      content: ContentShell(
        scrollable: false,
        child: listAsync.when(
          loading: () => ListPageLoadingShell(topBar: toolbar0(const [])),
          error:   (_, __) => ListPageErrorShell(
            topBar:      toolbar0(const []),
            title:       loc.mod_preset_error_title,
            description: loc.error_startup_message,
            primaryLabel: loc.common_retry,
            onPrimary: () => ref.invalidate(orderedModPresetsForUiProvider),
          ),
          data: (List<ModPresetView> list) {
            if (inReorder) {
              final workingNow = ref.read(modPresetsWorkingOrderProvider);
              final merged = mergeWorkingOrder(workingNow, list, (e) => e.key);
              if (merged.length != workingNow.length || !const ListEquality().equals(merged, workingNow)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !ref.read(modPresetsReorderModeProvider)) return;
                  final latestList = ref.read(orderedModPresetsForUiProvider).maybeWhen(data: (l) => l, orElse: () => list);
                  final latestWorking = ref.read(modPresetsWorkingOrderProvider);
                  final mergedLatest = mergeWorkingOrder(latestWorking, latestList, (e) => e.key);
                  ref.read(modPresetsWorkingOrderProvider.notifier).setAll(mergedLatest);
                  ref.read(modPresetsReorderDirtyProvider.notifier).state = true;
                });
              }
            }

            final toolbar = toolbar0(list);

            if (list.isEmpty) {
              return ListPageEmptyShell.with404(
                topBar: toolbar,
                title: loc.mod_preset_empty_title,
                primaryLabel: loc.mod_preset_create_button,
                onPrimary: createFlow,
              );
            }

            BadgeCardTile buildTile(ModPresetView v, {bool disableTap = false}) {
              final enabledLabel = loc.mod_preset_enabled_mods(v.enabledCount);
              return BadgeCardTile(
                title: v.name,
                badges: [BadgeSpec(enabledLabel, accent2StatusOf(context, ref))],
                inEditMode: inReorder,
                onDelete: inReorder
                    ? () async {
                  await ref.read(modPresetsControllerProvider.notifier).remove(v.key);
                  ref.read(modPresetsReorderDirtyProvider.notifier).state = true;
                  _autosave.bump();
                }
                    : null,
                onTap: disableTap ? () {} : () => _goDetail(v.key, v.name),
                menuBuilder: (ctx) => MenuFlyout(
                  color: fTheme.scaffoldBackgroundColor,
                  items: [
                    if (!inReorder)
                      MenuFlyoutItem(
                        text: Text(loc.mod_preset_menu_reorder),
                        leading: const Icon(FluentIcons.drag_object),
                        onPressed: () => _enterReorder(list),
                      ),
                    MenuFlyoutItem(
                      text: Text(loc.common_duplicate),
                      leading: const Icon(FluentIcons.copy),
                      onPressed: () async {
                        await ref.read(modPresetsControllerProvider.notifier).clone(
                          v.key,
                          duplicateSuffix: loc.common_duplicate_suffix,
                        );
                      },
                    ),
                    MenuFlyoutItem(
                      text: Text(loc.common_delete),
                      leading: const Icon(FluentIcons.delete),
                      onPressed: () async {
                        await ref.read(modPresetsControllerProvider.notifier).remove(v.key);
                      },
                    ),
                  ],
                ),
              );
            }

            // 길게 눌러 정렬 모드 진입(모바일/터치 대비)
            Widget buildTileWithLongPress(ModPresetView v) {
              return GestureDetector(
                onLongPress: () => _enterReorder(list),
                child: buildTile(v),
              );
            }

            return Column(
              children: [
                toolbar,
                Gaps.h12,
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = _calcCols(constraints.maxWidth);
                      const spacing = AppSpacing.sm;

                      Widget card(ModPresetView v, {required bool forReorder}) => Wiggle(
                        enabled: inReorder,
                        phaseSeed: (v.key.hashCode % 628) / 100.0,
                        child: forReorder ? buildTile(v, disableTap: true) : buildTileWithLongPress(v),
                      );

                      return ReorderGrid<ModPresetView>(
                        items: list,
                        idOf: (e) => e.key,
                        inReorder: inReorder,
                        crossAxisCount: cols,
                        spacing: spacing,
                        mainAxisExtent: 100,
                        normalScrollController: _normalScroll,
                        editScrollController: _editScroll,
                        normalItemBuilder: (item) => card(item, forReorder: false),
                        reorderItemBuilder: (item) => card(item, forReorder: true),
                        onReorder: (newIds) {
                          ref.read(modPresetsWorkingOrderProvider.notifier).setAll(newIds);
                          if (!_dragReportedDirty) {
                            _dragReportedDirty = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                ref.read(modPresetsReorderDirtyProvider.notifier).state = true;
                              }
                            });
                          }
                          _autosave.bump();
                        },
                        onHoverDuringReorder: _autosave.bump,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
