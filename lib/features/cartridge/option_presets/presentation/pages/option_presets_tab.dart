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
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/id.dart';
import 'package:cartridge/core/utils/wiggle.dart';
import 'package:cartridge/features/cartridge/option_presets/domain/models/option_preset_view.dart';
import 'package:cartridge/features/cartridge/option_presets/presentation/controllers/option_presets_page_controller.dart';
import 'package:cartridge/features/cartridge/option_presets/presentation/widgets/option_presets_create_edit_dialog.dart';
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
    _searchCtrl.dispose();
    _normalScroll.dispose();
    _editScroll.dispose();
    super.dispose();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDuration, () async {
      if (!ref.read(optionPresetsReorderModeProvider)) return;
      final ids   = ref.read(optionPresetsWorkingOrderProvider);
      final dirty = ref.read(optionPresetsReorderDirtyProvider);
      final loc = AppLocalizations.of(context);

      if (dirty) {
        final result = await ref.read(optionPresetsControllerProvider.notifier).reorderOptionPresets(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, loc.option_reorder_saved_title,     loc.option_reorder_saved_desc),
          notFound: (_, __)      async => UiFeedback.warn(context,    loc.option_reorder_not_found_title,  loc.option_reorder_not_found_desc),
          invalid:  (_, __, ___) async => UiFeedback.error(context,   loc.option_reorder_invalid_title,    loc.option_reorder_invalid_desc),
          conflict: (_, __)      async => UiFeedback.warn(context,    loc.option_reorder_conflict_title,   loc.option_reorder_conflict_desc),
          failure:  (_, __, ___) async => UiFeedback.error(context,   loc.option_reorder_failure_title,    loc.option_reorder_failure_desc),
        );
      }
      ref.read(optionPresetsReorderModeProvider.notifier).state  = false;
      ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
      _dragReportedDirty = false;
      _idleTimer?.cancel();
    });
  }

  void _bumpIdleTimer() {
    if (ref.read(optionPresetsReorderModeProvider)) _startIdleTimer();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(optionPresetsQueryProvider.notifier).state = v.trim();

      if (ref.read(optionPresetsReorderModeProvider)) {
        ref.read(optionPresetsReorderModeProvider.notifier).state = false;
        ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
        ref.read(optionPresetsWorkingOrderProvider.notifier).reset();
        _dragReportedDirty = false;
      }
    });
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
    final q         = ref.watch(optionPresetsQueryProvider);

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
              _idleTimer?.cancel();
              _dragReportedDirty = false;
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
              _idleTimer?.cancel();
            }
                : null,
            child: Text(loc.common_save),
          ),
        ]
            : [
          Button(
            onPressed: () async {
              // 생성/수정 플로우 (신규)
              final repInstalled = await ref.read(optionPresetsControllerProvider.notifier).isRepentogonInstalled();
              OptionPresetView? init;
              try {
                init = await ref.read(optionPresetInitialFromCurrentProvider.future);
              } catch (_) {
                init = null;
              }
              if (!context.mounted) return;
              final result = await showOptionPresetsCreateEditDialog(context,
                initial: init,
                repentogonInstalled: repInstalled,
              );
              if (result == null) return;

              final ctl = ref.read(optionPresetsControllerProvider.notifier);
              if (init == null) {
                final withId = result.id.trim().isEmpty ? result.copyWith(id: IdUtil.genId('op')) : result;
                await ctl.create(withId);
              } else {
                await ctl.fetch(result);
              }
            },
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
            onPressed: () {
              if (q.trim().isNotEmpty) {
                UiFeedback.warn(context, loc.option_reorder_unavailable_title, loc.option_reorder_unavailable_desc);
                return;
              }
              ref.read(optionPresetsReorderModeProvider.notifier).state  = true;
              ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
              ref.read(optionPresetsWorkingOrderProvider.notifier).syncFrom(currentList);
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
            title: loc.option_error_title,
            description: loc.error_startup_message,
            primaryLabel: loc.common_retry,
            onPrimary: () => ref.invalidate(orderedOptionPresetsForUiProvider),
          ),
          data: (List<OptionPresetView> list) {
            if (inReorder) {
              final working = ref.read(optionPresetsWorkingOrderProvider);
              final curIds  = list.map((e) => e.id).toList(growable: false);
              final next = <String>[
                ...working.where(curIds.contains),
                ...curIds.where((id) => !working.contains(id)),
              ];
              if (next.length != working.length || !const ListEquality().equals(next, working)) {
                ref.read(optionPresetsWorkingOrderProvider.notifier).setAll(next);
                ref.read(optionPresetsReorderDirtyProvider.notifier).state = true;
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
                        title: loc.option_empty_title,
                        primaryLabel: loc.option_create_button,
                        onPrimary: () async {
                          final repInstalled = await ref.read(optionPresetsControllerProvider.notifier).isRepentogonInstalled();
                          if (!context.mounted) return;
                          final res = await showOptionPresetsCreateEditDialog(context,
                            repentogonInstalled: repInstalled,
                          );
                          if (res == null) return;
                          final ctl = ref.read(optionPresetsControllerProvider.notifier);
                          final withId = res.id.trim().isNotEmpty ? res : res.copyWith(id: IdUtil.genId('op'));
                          await ctl.create(withId);
                        },
                      ),
                    ),
                  ),
                ],
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
                  _bumpIdleTimer();
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
                        onPressed: () {
                          if (q.trim().isNotEmpty) {
                            UiFeedback.warn(context, loc.option_reorder_unavailable_title, loc.option_reorder_unavailable_desc);
                            return;
                          }
                          ref.read(optionPresetsReorderModeProvider.notifier).state  = true;
                          ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
                          ref.read(optionPresetsWorkingOrderProvider.notifier).syncFrom(list);
                          _dragReportedDirty = false;
                          _startIdleTimer();
                        },
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

            // 길게 눌러 정렬 모드 진입 지원(모바일/터치 대비)
            Widget buildTileWithLongPress(OptionPresetView v) {
              return GestureDetector(
                onLongPress: () {
                  if (inReorder) return;
                  if (q.trim().isNotEmpty) return;
                  ref.read(optionPresetsReorderModeProvider.notifier).state  = true;
                  ref.read(optionPresetsReorderDirtyProvider.notifier).state = false;
                  ref.read(optionPresetsWorkingOrderProvider.notifier).syncFrom(list);
                  _dragReportedDirty = false;
                  _startIdleTimer();
                },
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

                      Widget card(OptionPresetView v) => SizedBox(
                        width: itemWidth,
                        child: Wiggle(
                          enabled: inReorder,
                          phaseSeed: (v.id.hashCode % 628) / 100.0,
                          child: inReorder ? buildTile(v, disableTap: true) : buildTileWithLongPress(v),
                        ),
                      );

                      if (inReorder) {
                        final children = [
                          for (final v in list)
                            RepaintBoundary(
                              key: ValueKey(v.id),
                              child: SizedBox(width: itemWidth, child: card(v)),
                            ),
                        ];

                        return ReorderableBuilder<_Fake>(
                          scrollController: _editScroll,
                          enableLongPress: false,
                          onReorder: (reorderFn) {
                            final idsBefore = ref.read(optionPresetsWorkingOrderProvider);
                            final fake  = idsBefore.map((e) => _Fake(id: e)).toList();
                            final after = reorderFn(fake).cast<_Fake>().map((e) => e.id).toList();

                            ref.read(optionPresetsWorkingOrderProvider.notifier).setAll(after);
                            if (!_dragReportedDirty) {
                              _dragReportedDirty = true;
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  ref.read(optionPresetsReorderDirtyProvider.notifier).state = true;
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
