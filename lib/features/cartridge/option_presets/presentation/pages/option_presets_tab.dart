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
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/wiggle.dart';
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class OptionPresetsTab extends ConsumerStatefulWidget {
  const OptionPresetsTab({super.key});

  @override
  ConsumerState<OptionPresetsTab> createState() => _OptionPresetsTabState();
}

class _OptionPresetsTabState extends ConsumerState<OptionPresetsTab> {
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
      isEnabled: () => ref.read(optionPresetsReorderModeProvider),
      isDirty:   () => ref.read(optionPresetsReorderDirtyProvider),
      getIds:    () => ref.read(optionPresetsWorkingOrderProvider),
      commit: (ids) async {
        final loc = AppLocalizations.of(context);
        final result = await ref.read(optionPresetsControllerProvider.notifier).reorderOptionPresets(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, loc.option_reorder_saved_title,     loc.option_reorder_saved_desc),
          notFound: (_, __)      async => UiFeedback.warn(context,    loc.option_reorder_not_found_title,  loc.option_reorder_not_found_desc),
          invalid:  (_, __, ___) async => UiFeedback.error(context,   loc.option_reorder_invalid_title,    loc.option_reorder_invalid_desc),
          conflict: (_, __)      async => UiFeedback.warn(context,    loc.option_reorder_conflict_title,   loc.option_reorder_conflict_desc),
          failure:  (_, __, ___) async => UiFeedback.error(context,   loc.option_reorder_failure_title,    loc.option_reorder_failure_desc),
        );
      },
      resetAfterSave: () {
        ref.read(optionPresetsReorderModeProvider.notifier).state  = false;
        ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
        _dragReportedDirty = false;
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _autosave.cancel();
    _searchCtrl.dispose();
    _normalScroll.dispose();
    _editScroll.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(optionPresetsQueryProvider.notifier).state = v.trim();
      if (ref.read(optionPresetsReorderModeProvider)) {
        ref.read(optionPresetsReorderModeProvider.notifier).state  = false;
        ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
        ref.read(optionPresetsWorkingOrderProvider.notifier).reset();
        _dragReportedDirty = false;
        _autosave.cancel();
      }
    });
  }

  Future<void> createFlow() async {
    final repInstalled = await ref.read(optionPresetsControllerProvider.notifier).isRepentogonInstalled();
    OptionPresetView? init;
    try {
      init = await ref.read(optionPresetInitialFromCurrentProvider.future);
    } catch (_) {
      init = null;
    }
    if (!mounted) return;
    final result = await showOptionPresetsCreateEditDialog(
      context,
      initial: init,
      repentogonInstalled: repInstalled,
    );
    if (result == null) return;

    final ctl = ref.read(optionPresetsControllerProvider.notifier);
    if (init?.id == null || init!.id.isEmpty) {
      await ctl.create(result);
    } else {
      await ctl.fetch(result);
    }
  }

  void _enterReorder(List<OptionPresetView> currentList) {
    final q = ref.read(optionPresetsQueryProvider).trim();
    final loc = AppLocalizations.of(context);
    if (q.isNotEmpty) {
      UiFeedback.warn(context, loc.option_reorder_unavailable_title, loc.option_reorder_unavailable_desc);
      return;
    }
    ref.read(optionPresetsReorderModeProvider.notifier).state  = true;
    ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
    ref.read(optionPresetsWorkingOrderProvider.notifier).syncFrom(currentList);
    _dragReportedDirty = false;
    _autosave.start();
  }

  int _calcCols(double maxW) {
    if (maxW >= AppBreakpoints.lg) return 4;
    if (maxW >= AppBreakpoints.md) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final loc    = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    final listAsync = ref.watch(orderedOptionPresetsForUiProvider);
    final inReorder = ref.watch(optionPresetsReorderModeProvider);
    final dirty     = ref.watch(optionPresetsReorderDirtyProvider);

    // 상단 툴바 (로딩/에러에서도 항상 유지)
    Widget toolbar0(List<OptionPresetView> currentList) {
      return SearchToolbar(
        controller: _searchCtrl,
        placeholder: loc.option_search_placeholder,
        onChanged: _onSearchChanged,
        enabled: !inReorder,
        actions: inReorder
            ? [
          Button(
            onPressed: () {
              ref.read(optionPresetsReorderModeProvider.notifier).state  = false;
              ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
              ref.read(optionPresetsWorkingOrderProvider.notifier).syncFrom(currentList);
              _dragReportedDirty = false;
              _autosave.cancel();
            },
            child: Text(loc.common_cancel),
          ),
          Gaps.w8,
          FilledButton(
            onPressed: dirty
                ? () async {
              final ids = ref.read(optionPresetsWorkingOrderProvider);
              final result = await ref.read(optionPresetsControllerProvider.notifier).reorderOptionPresets(ids);
              await result.when(
                ok:       (_, __, ___) async {
                  ref.read(optionPresetsReorderModeProvider.notifier).state  = false;
                  ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
                  UiFeedback.success(context, loc.option_reorder_saved_title, loc.option_reorder_saved_desc);
                  _dragReportedDirty = false;
                },
                notFound: (_, __)      async => UiFeedback.warn(context,  loc.option_reorder_not_found_title, loc.option_reorder_not_found_desc),
                invalid:  (_, __, ___) async => UiFeedback.error(context, loc.option_reorder_invalid_title,    loc.option_reorder_invalid_desc),
                conflict: (_, __)      async => UiFeedback.warn(context,  loc.option_reorder_conflict_title,   loc.option_reorder_conflict_desc),
                failure:  (_, __, ___) async => UiFeedback.error(context, loc.option_reorder_failure_title,    loc.option_reorder_failure_desc),
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
                Text(loc.option_create_button),
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
            topBar: toolbar0(const []),
            title:       loc.option_error_title,
            description: loc.error_startup_message,
            primaryLabel: loc.common_retry,
            onPrimary: () => ref.invalidate(orderedOptionPresetsForUiProvider),
          ),
          data: (List<OptionPresetView> list) {
            if (inReorder) {
              final workingNow = ref.read(optionPresetsWorkingOrderProvider);
              final merged = mergeWorkingOrder(workingNow, list, (e) => e.id);
              if (merged.length != workingNow.length || !const ListEquality().equals(merged, workingNow)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !ref.read(optionPresetsReorderModeProvider)) return;
                  final latestList = ref.read(orderedOptionPresetsForUiProvider).maybeWhen(data: (l) => l, orElse: () => list);
                  final latestWorking = ref.read(optionPresetsWorkingOrderProvider);
                  final mergedLatest = mergeWorkingOrder(latestWorking, latestList, (e) => e.id);
                  ref.read(optionPresetsWorkingOrderProvider.notifier).setAll(mergedLatest);
                  ref.read(optionPresetsReorderDirtyProvider.notifier).state = true;
                });
              }
            }

            final toolbar = toolbar0(list);

            if (list.isEmpty) {
              return ListPageEmptyShell.with404(
                topBar: toolbar,
                title: loc.option_empty_title,
                primaryLabel: loc.option_create_button,
                onPrimary: createFlow,
              );
            }

            BadgeCardTile buildTile(OptionPresetView v, {bool disableTap = false}) {
              final badges = <BadgeSpec>[BadgeSpec(v.primaryLabel, accent2StatusOf(context, ref))];
              if (v.useRepentogon == true) {
                badges.add(BadgeSpec(AppLocalizations.of(context).option_use_repentogon_label, repentogonStatusOf(context, ref)));
              }
              return BadgeCardTile(
                title: v.name,
                badges: badges,
                inEditMode: inReorder,
                onDelete: inReorder
                    ? () async {
                  await ref.read(optionPresetsControllerProvider.notifier).remove(v.id);
                  ref.read(optionPresetsReorderDirtyProvider.notifier).state = true;
                  _autosave.bump();
                }
                    : null,
                onTap: disableTap
                    ? () {}
                    : () async {
                  final repInstalled = await ref.read(optionPresetsControllerProvider.notifier).isRepentogonInstalled();
                  if (!context.mounted) return;
                  final res = await showOptionPresetsCreateEditDialog(context, initial: v, repentogonInstalled: repInstalled);
                  if (res == null) return;
                  await ref.read(optionPresetsControllerProvider.notifier).fetch(res);
                },
                menuBuilder: (ctx) => MenuFlyout(
                  color: fTheme.scaffoldBackgroundColor,
                  items: [
                    if (!inReorder)
                      MenuFlyoutItem(
                        text: Text(loc.option_menu_reorder),
                        leading: const Icon(FluentIcons.drag_object),
                        onPressed: () => _enterReorder(list),
                      ),
                    MenuFlyoutItem(
                      text: Text(loc.common_duplicate),
                      leading: const Icon(FluentIcons.copy),
                      onPressed: () async {
                        await ref.read(optionPresetsControllerProvider.notifier).clone(
                          v.id,
                          loc.common_duplicate_suffix,
                        );
                      },
                    ),
                    MenuFlyoutItem(
                      text: Text(loc.common_delete),
                      leading: const Icon(FluentIcons.delete),
                      onPressed: () async {
                        await ref.read(optionPresetsControllerProvider.notifier).remove(v.id);
                      },
                    ),
                  ],
                ),
              );
            }

            // 길게 눌러 정렬 모드 진입
            Widget buildTileWithLongPress(OptionPresetView v) {
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
                      final itemWidth =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;

                      Widget card(OptionPresetView v, {required bool forReorder}) => SizedBox(
                        width: itemWidth,
                        child: Wiggle(
                          enabled: inReorder,
                          phaseSeed: (v.id.hashCode % 628) / 100.0,
                          child: forReorder
                              ? buildTile(v, disableTap: true)
                              : buildTileWithLongPress(v),
                        ),
                      );

                      return ReorderGrid<OptionPresetView>(
                        items: list,
                        idOf: (e) => e.id,
                        inReorder: inReorder,
                        crossAxisCount: cols,
                        spacing: spacing,
                        mainAxisExtent: 100,
                        normalScrollController: _normalScroll,
                        editScrollController: _editScroll,
                        normalItemBuilder: (item) => card(item, forReorder: false),
                        reorderItemBuilder: (item) => card(item, forReorder: true),
                        onReorder: (newIds) {
                          ref.read(optionPresetsWorkingOrderProvider.notifier).setAll(newIds);
                          if (!_dragReportedDirty) {
                            _dragReportedDirty = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                ref.read(optionPresetsReorderDirtyProvider.notifier).state = true;
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
