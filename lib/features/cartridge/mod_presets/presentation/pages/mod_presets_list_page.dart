import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/app/presentation/widgets/list_page/list_page.dart';
import 'package:cartridge/app/presentation/widgets/list_tiles.dart';
import 'package:cartridge/app/presentation/widgets/search_toolbar.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/result.dart';
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
  Timer? _idleTimer;
  static const _idleDuration = Duration(minutes: 1);
  bool _dragReportedDirty = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _idleTimer?.cancel();
    _normalScroll.dispose();
    _editScroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDuration, () async {
      if (!ref.read(modPresetsReorderModeProvider)) return;
      final ids   = ref.read(modPresetsWorkingOrderProvider);
      final dirty = ref.read(modPresetsReorderDirtyProvider);
      final loc = AppLocalizations.of(context);

      if (dirty) {
        final result = await ref.read(modPresetsControllerProvider.notifier).reorderModPresets(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, loc.mod_preset_reorder_saved_title, loc.mod_preset_reorder_saved_desc),
          notFound: (_, __)      async => UiFeedback.warn(context,    loc.mod_preset_reorder_not_found_title, loc.mod_preset_reorder_not_found_desc),
          invalid:  (_, __, ___) async => UiFeedback.error(context,   loc.mod_preset_reorder_invalid_title,   loc.mod_preset_reorder_invalid_desc),
          conflict: (_, __)      async => UiFeedback.warn(context,    loc.mod_preset_reorder_conflict_title,  loc.mod_preset_reorder_conflict_desc),
          failure:  (_, __, ___) async => UiFeedback.error(context,   loc.mod_preset_reorder_failure_title,   loc.mod_preset_reorder_failure_desc),
        );
      }
      ref.read(modPresetsReorderModeProvider.notifier).state  = false;
      ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
      _dragReportedDirty = false;
      _idleTimer?.cancel();
    });
  }

  void _bumpIdleTimer() {
    if (ref.read(modPresetsReorderModeProvider)) _startIdleTimer();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(modPresetsQueryProvider.notifier).state = v.trim();
      // 검색 중에는 정렬 종료
      if (ref.read(modPresetsReorderModeProvider)) {
        ref.read(modPresetsReorderModeProvider.notifier).state = false;
        ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
        ref.read(modPresetsWorkingOrderProvider.notifier).reset();
        _dragReportedDirty = false;
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

  // 생성 플로우
  Future<void> createFlow() async {
    final res = await showCreatePresetDialog(context);
    if (res == null) return;

    final result = await ref
        .read(modPresetsControllerProvider.notifier)
        .create(name: res.name, seedMode: res.seedMode);

    await result.when(
      ok: (data, _, __) async { if (data != null) await _goDetail(data.key, data.name); },
      notFound: (_, __) async {}, invalid: (_, __, ___) async {},
      conflict: (_, __) async {}, failure: (_, __, ___) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc   = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    final listAsync = ref.watch(orderedModPresetsForUiProvider);
    final inReorder = ref.watch(modPresetsReorderModeProvider);
    final dirty     = ref.watch(modPresetsReorderDirtyProvider);
    final q         = ref.watch(modPresetsQueryProvider);

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
              _idleTimer?.cancel();
              _dragReportedDirty = false;
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
                  UiFeedback.success(context, loc.mod_preset_reorder_saved_title, loc.mod_preset_reorder_saved_desc);
                  _dragReportedDirty = false;
                },
                notFound: (_, __)      async => UiFeedback.warn(context,  loc.mod_preset_reorder_not_found_title, loc.mod_preset_reorder_not_found_desc),
                invalid:  (_, __, ___) async => UiFeedback.error(context, loc.mod_preset_reorder_invalid_title,   loc.mod_preset_reorder_invalid_desc),
                conflict: (_, __)      async => UiFeedback.warn(context,  loc.mod_preset_reorder_conflict_title,  loc.mod_preset_reorder_conflict_desc),
                failure:  (_, __, ___) async => UiFeedback.error(context, loc.mod_preset_reorder_failure_title,   loc.mod_preset_reorder_failure_desc),
              );
              _idleTimer?.cancel();
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
            onPressed: () {
              if (q.trim().isNotEmpty) {
                UiFeedback.warn(context, loc.mod_preset_reorder_unavailable_title, loc.mod_preset_reorder_unavailable_desc);
                return;
              }
              ref.read(modPresetsReorderModeProvider.notifier).state  = true;
              ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
              ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(currentList);
              _dragReportedDirty = false;
              _startIdleTimer();
            },
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
          error: (_, __) => ListPageErrorShell(
            topBar: toolbar0(const []),
            title: loc.mod_preset_error_title,
            description: loc.error_startup_message,
            primaryLabel: loc.common_retry,
            onPrimary: () => ref.invalidate(orderedModPresetsForUiProvider),
          ),
          data: (List<ModPresetView> list) {
            if (inReorder) {
              final working = ref.read(modPresetsWorkingOrderProvider);
              final curIds  = list.map((e) => e.key).toList(growable: false);
              final next = <String>[
                ...working.where(curIds.contains),
                ...curIds.where((id) => !working.contains(id)),
              ];
              if (next.length != working.length || !const ListEquality().equals(next, working)) {
                ref.read(modPresetsWorkingOrderProvider.notifier).setAll(next);
                ref.read(modPresetsReorderDirtyProvider.notifier).state = true;
              }
            }

            final toolbar = toolbar0(list);

            if (list.isEmpty) {
              return Column(
                children: [
                  toolbar,
                  Gaps.h12,
                  Expanded(
                    child: Center(
                      child: EmptyState.withDefault404(
                        title: loc.mod_preset_empty_title,
                        primaryLabel: loc.mod_preset_create_button,
                        onPrimary: createFlow,
                      ),
                    ),
                  ),
                ],
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
                  _bumpIdleTimer();
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
                        onPressed: () {
                          if (q.trim().isNotEmpty) {
                            UiFeedback.warn(context, loc.mod_preset_reorder_unavailable_title, loc.mod_preset_reorder_unavailable_desc);
                            return;
                          }
                          ref.read(modPresetsReorderModeProvider.notifier).state  = true;
                          ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                          ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(list);
                          _dragReportedDirty = false;
                          _startIdleTimer();
                        },
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

            BadgeCardTile buildInnerTile(ModPresetView v) {
              final enabledLabel = loc.mod_preset_enabled_mods(v.enabledCount);
              final badges = <BadgeSpec>[BadgeSpec(enabledLabel, accent2StatusOf(context, ref))];
              return BadgeCardTile(
                title: v.name,
                badges: badges,
                onTap: () => _goDetail(v.key, v.name),
                menuBuilder: (ctx) => MenuFlyout(
                  color: fTheme.scaffoldBackgroundColor,
                  items: [
                    MenuFlyoutItem(
                      text: Text(loc.mod_preset_menu_reorder),
                      leading: const Icon(FluentIcons.drag_object),
                      onPressed: () {
                        if (q.trim().isNotEmpty) {
                          UiFeedback.warn(context, loc.mod_preset_reorder_unavailable_title, loc.mod_preset_reorder_unavailable_desc);
                          return;
                        }
                        ref.read(modPresetsReorderModeProvider.notifier).state  = true;
                        ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                        ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(list);
                        _dragReportedDirty = false;
                        _startIdleTimer();
                      },
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

            Widget buildTileWithLongPress(ModPresetView v) {
              return GestureDetector(
                onLongPress: () {
                  if (inReorder) return;
                  if (q.trim().isNotEmpty) return;
                  ref.read(modPresetsReorderModeProvider.notifier).state  = true;
                  ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                  ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(list);
                  _dragReportedDirty = false;
                  _startIdleTimer();
                },
                child: buildInnerTile(v),
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
                      final itemWidth =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;

                      Widget card(ModPresetView v) => SizedBox(
                        width: itemWidth,
                        child: Wiggle(
                          enabled: inReorder,
                          phaseSeed: (v.key.hashCode % 628) / 100.0,
                          child: inReorder
                              ? buildTile(v, disableTap: true)
                              : buildTileWithLongPress(v),
                        ),
                      );

                      if (inReorder) {
                        final children = [
                          for (final v in list)
                            RepaintBoundary(
                              key: ValueKey(v.key),
                              child: SizedBox(
                                width: itemWidth,
                                child: card(v),
                              ),
                            ),
                        ];

                        return ReorderableBuilder<_Fake>(
                          scrollController: _editScroll,
                          enableLongPress: false,
                          onReorder: (reorderFn) {
                            final idsBefore = ref.read(modPresetsWorkingOrderProvider);
                            final fake  = idsBefore.map((e) => _Fake(id: e)).toList();
                            final after = reorderFn(fake).cast<_Fake>().map((e) => e.id).toList();

                            ref.read(modPresetsWorkingOrderProvider.notifier).setAll(after);
                            if (!_dragReportedDirty) {
                              _dragReportedDirty = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ref.read(modPresetsReorderDirtyProvider.notifier).state = true;
                                }
                              });
                            }
                            _bumpIdleTimer();
                          },
                          builder: (reorderedChildren) {
                            return MouseRegion(
                              onHover: (_) => _bumpIdleTimer(),
                              child: RepaintBoundary(
                                child: GridView(
                                  controller: _editScroll,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: spacing,
                                    mainAxisSpacing: spacing,
                                    mainAxisExtent: 100,
                                  ),
                                  children: reorderedChildren,
                                ),
                              ),
                            );
                          },
                          children: children,
                        );
                      }

                      return GridView.builder(
                        controller: _normalScroll,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          mainAxisExtent: 100,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) => card(list[i]),
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

class _Fake {
  final String id;
  _Fake({required this.id});
}
