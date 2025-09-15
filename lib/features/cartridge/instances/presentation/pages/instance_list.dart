import 'dart:async';
import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/app/presentation/widgets/list_page/list_page.dart';
import 'package:cartridge/app/presentation/widgets/search_toolbar.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/wiggle.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/sprite_sheet.dart' as ss;
import 'package:cartridge/features/cartridge/option_presets/option_presets.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

/// 인스턴스 목록 페이지(검색/생성/복제/삭제 + 목록/카드 UI)
class InstanceListPage extends ConsumerStatefulWidget {
  final void Function(String instanceId, String instanceName) onSelect;
  const InstanceListPage({super.key, required this.onSelect});

  @override
  ConsumerState<InstanceListPage> createState() => _InstanceListPageState();
}

class _InstanceListPageState extends ConsumerState<InstanceListPage> {
  final _searchCtrl = TextEditingController();
  final _normalScroll = ScrollController();
  final _editScroll   = ScrollController();
  Timer? _debounce;
  late final ReorderAutosave _autosave;
  bool _dragReportedDirty = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    ss.SpriteSheetLoader.load('assets/images/instance_thumbs.png');
    _autosave = ReorderAutosave(
      duration: const Duration(minutes: 1),
      isEnabled: () => ref.read(instancesReorderModeProvider),
      isDirty:   () => ref.read(instancesReorderDirtyProvider),
      getIds:    () => ref.read(instancesWorkingOrderProvider),
      commit: (ids) async {
        final loc = AppLocalizations.of(context);
        final result = await ref.read(instancesControllerProvider.notifier).reorderInstances(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, title: loc.common_saved,     content: loc.instance_reorder_saved_desc),
          notFound: (_, __)      async => UiFeedback.warn(context,    title: loc.common_not_found,  content: loc.instance_reorder_not_found_desc),
          invalid:  (_, __, ___) async => UiFeedback.error(context,   title: loc.common_save_fail,    content: loc.instance_reorder_invalid_desc),
          conflict: (_, __)      async => UiFeedback.warn(context, content: loc.instance_reorder_conflict_desc),
          failure:  (_, __, ___) async => UiFeedback.error(context, content: loc.instance_reorder_failure_desc),
        );
      },
      resetAfterSave: () {
        ref.read(instancesReorderModeProvider.notifier).state  = false;
        ref.read(instancesReorderDirtyProvider.notifier).state = false;
        _dragReportedDirty = false;
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _normalScroll.dispose();
    _editScroll.dispose();
    _searchCtrl.dispose();
    _autosave.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(instancesQueryProvider.notifier).state = v.trim();
      if (ref.read(instancesReorderModeProvider)) {
        ref.read(instancesReorderModeProvider.notifier).state = false;
        ref.read(instancesReorderDirtyProvider.notifier).state = false;
        ref.read(instancesWorkingOrderProvider.notifier).reset();
        _dragReportedDirty = false;
        _autosave.cancel();
      }
    });
  }

  Future<void> createFlow() async {
    final res = await showCreateInstanceDialog(context);
    if (res == null) return;
    final result = await ref.read(instancesControllerProvider.notifier).createInstance(
      name: res.name,
      seedMode: res.seedMode,
      presetIds: res.presetIds,
      optionPresetId: res.optionPresetId,
    );
    await result.when(
      ok: (data, _, __) async { if (data != null) await _goDetail(data.id, data.name); },
      notFound: (_, __) async {},
      invalid:  (_, __, ___) async {},
      conflict: (_, __) async {},
      failure:  (_, __, ___) async {},
    );
  }

  void _enterReorder(List<InstanceView> currentList) {
    final q = ref.read(instancesQueryProvider).trim();
    final loc = AppLocalizations.of(context);
    if (q.isNotEmpty) {
      UiFeedback.warn(context, title: loc.instance_reorder_unavailable_title, content: loc.instance_reorder_unavailable_desc);
      return;
    }
    ref.read(instancesReorderModeProvider.notifier).state  = true;
    ref.read(instancesReorderDirtyProvider.notifier).state = false;
    ref.read(instancesWorkingOrderProvider.notifier).syncFrom(currentList);
    _dragReportedDirty = false;
    _autosave.start();
  }

  Future<void> _goDetail(String id, String name) async {
    widget.onSelect(id, name);
  }

  int _calcCols(double maxW) => maxW >= AppBreakpoints.md ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);
    ref.watch(optionPresetsControllerProvider);

    final listAsync = ref.watch(orderedInstancesForUiProvider);
    final inReorder = ref.watch(instancesReorderModeProvider);
    final dirty     = ref.watch(instancesReorderDirtyProvider);

    Widget toolbar(List<InstanceView> currentList) {
      return SearchToolbar(
        controller: _searchCtrl,
        placeholder: loc.instance_search_placeholder,
        onChanged: _onSearchChanged,
        enabled: !inReorder,
        actions: inReorder
            ? [
          Button(
            onPressed: () {
              ref.read(instancesReorderModeProvider.notifier).state  = false;
              ref.read(instancesReorderDirtyProvider.notifier).state = false;
              ref.read(instancesWorkingOrderProvider.notifier).syncFrom(currentList);
              _dragReportedDirty = false;
              _autosave.cancel();
            },
            child: Text(loc.common_cancel),
          ),
          Gaps.w8,
          FilledButton(
            onPressed: dirty
                ? () async {
              final ids = ref.read(instancesWorkingOrderProvider);
              final result = await ref.read(instancesControllerProvider.notifier).reorderInstances(ids);
              await result.when(
                ok:       (_, __, ___) async {
                  ref.read(instancesReorderModeProvider.notifier).state  = false;
                  ref.read(instancesReorderDirtyProvider.notifier).state = false;
                  UiFeedback.success(context, title: loc.common_saved, content: loc.instance_reorder_saved_desc);
                  _dragReportedDirty = false;
                },
                notFound: (_, __)      async => UiFeedback.warn(context, title: loc.common_not_found, content: loc.instance_reorder_not_found_desc),
                invalid:  (_, __, ___) async => UiFeedback.error(context, title: loc.common_saved, content: loc.instance_reorder_invalid_desc),
                conflict: (_, __)      async => UiFeedback.warn(context, content: loc.instance_reorder_conflict_desc),
                failure:  (_, __, ___) async => UiFeedback.error(context, content: loc.instance_reorder_failure_desc),
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
                Text(loc.instance_create_button),
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
          loading: () => ListPageLoadingShell(topBar: toolbar(const [])),
          error: (_, __) => ListPageErrorShell(
            topBar: toolbar(const []),
            title: loc.instance_error_title,
            description: loc.error_startup_message,
            primaryLabel: loc.common_retry,
            onPrimary: () => ref.invalidate(orderedInstancesForUiProvider),
          ),

          // ——— DATA ———
          data: (List<InstanceView> list) {

            // 정렬 모드일 때 워킹 오더 동기화
            if (inReorder) {
              final workingNow = ref.read(instancesWorkingOrderProvider);
              final merged = mergeWorkingOrder(workingNow, list, (e) => e.id);

              final needsUpdate = merged.length != workingNow.length
                  || !const ListEquality().equals(merged, workingNow);

              if (needsUpdate) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  if (!ref.read(instancesReorderModeProvider)) return;
                  final latestList = ref.read(orderedInstancesForUiProvider).maybeWhen(
                    data: (l) => l,
                    orElse: () => list,
                  );
                  final latestWorking = ref.read(instancesWorkingOrderProvider);
                  final mergedLatest = mergeWorkingOrder(latestWorking, latestList, (e) => e.id);

                  ref.read(instancesWorkingOrderProvider.notifier).setAll(mergedLatest);
                  ref.read(instancesReorderDirtyProvider.notifier).state = true;
                });
              }
            }


            if (list.isEmpty) {
              return ListPageEmptyShell.with404(
                topBar: toolbar(list),
                title: loc.instance_empty_message,
                primaryLabel: loc.instance_create_button,
                onPrimary: createFlow,
              );
            }

            // 타일 빌더(뱃지/메뉴 포함)
            InstanceBadgeCardTile buildTile(InstanceView v, {bool disableTap = false}) {
              final enabledLabel = loc.instance_enabled_mods(v.appliedPresets.length, v.enabledCount);
              final badges = <BadgeSpec>[BadgeSpec(enabledLabel, accent2StatusOf(context, ref))];

              if (v.optionPresetId != null && v.optionPresetId is String) {
                final optionPreset = ref.read(optionPresetByIdProvider(v.optionPresetId as String));
                if (optionPreset?.useRepentogon == true) {
                  badges.add(BadgeSpec(loc.option_use_repentogon_label, repentogonStatusOf(context, ref)));
                }
              }

              return InstanceBadgeCardTile(
                title: v.name,
                image: v.image,
                badges: badges,
                inEditMode: inReorder,
                onDeleteInstance: inReorder
                    ? () async {
                  await ref.read(instancesControllerProvider.notifier).deleteInstance(v.id);
                  ref.read(instancesReorderDirtyProvider.notifier).state = true;
                  _autosave.bump();
                }
                    : null,
                onPlayInstance: () async {
                  await ref.read(instancePlayServiceProvider).playByInstanceId(v.id);
                },
                onTap: disableTap ? () {} : () => _goDetail(v.id, v.name),
                menuBuilder: (ctx) => MenuFlyout(
                  color: fTheme.scaffoldBackgroundColor,
                  items: [
                    if (!inReorder)
                      MenuFlyoutItem(
                        text: Text(loc.instance_menu_reorder),
                        leading: const Icon(FluentIcons.drag_object),
                        onPressed: () => _enterReorder(list),
                      ),
                    MenuFlyoutItem(
                      text: Text(loc.common_duplicate),
                      leading: const Icon(FluentIcons.copy),
                      onPressed: () async {
                        await ref.read(instancesControllerProvider.notifier).duplicateInstance(
                          sourceId: v.id,
                          duplicateSuffix: loc.common_duplicate_suffix,
                        );
                      },
                    ),
                    MenuFlyoutItem(
                      text: Text(loc.common_delete),
                      leading: const Icon(FluentIcons.delete),
                      onPressed: () async {
                        await ref.read(instancesControllerProvider.notifier).deleteInstance(v.id);
                      },
                    ),
                  ],
                ),
              );
            }

            InstanceBadgeCardTile buildInnerTile(InstanceView v) {
              final enabledLabel = loc.instance_enabled_mods(v.appliedPresets.length, v.enabledCount);
              final badges = <BadgeSpec>[BadgeSpec(enabledLabel, accent2StatusOf(context, ref))];
              if (v.optionPresetId != null && v.optionPresetId is String) {
                final optionPreset = ref.read(optionPresetByIdProvider(v.optionPresetId as String));
                if (optionPreset?.useRepentogon == true) {
                  badges.add(BadgeSpec(loc.option_use_repentogon_label, repentogonStatusOf(context, ref)));
                }
              }
              return InstanceBadgeCardTile(
                title: v.name,
                image: v.image,
                badges: badges,
                onPlayInstance: () async {
                  await ref.read(instancePlayServiceProvider).playByInstanceId(v.id);
                },
                onTap: () => _goDetail(v.id, v.name),
                menuBuilder: (ctx) => MenuFlyout(
                  color: fTheme.scaffoldBackgroundColor,
                  items: [
                    MenuFlyoutItem(
                      text: Text(loc.instance_menu_reorder),
                      leading: const Icon(FluentIcons.drag_object),
                      onPressed: () => _enterReorder(list),
                    ),
                    MenuFlyoutItem(
                      text: Text(loc.common_duplicate),
                      leading: const Icon(FluentIcons.copy),
                      onPressed: () async {
                        await ref.read(instancesControllerProvider.notifier).duplicateInstance(
                          sourceId: v.id,
                          duplicateSuffix: loc.common_duplicate_suffix,
                        );
                      },
                    ),
                    MenuFlyoutItem(
                      text: Text(loc.common_delete),
                      leading: const Icon(FluentIcons.delete),
                      onPressed: () async {
                        await ref.read(instancesControllerProvider.notifier).deleteInstance(v.id);
                      },
                    ),
                  ],
                ),
              );
            }

            Widget buildTileWithLongPress(InstanceView v) {
              return GestureDetector(
                onLongPress: () => _enterReorder(list),
                child: buildInnerTile(v),
              );
            }

            // 목록/정렬 UI
            return Column(
              children: [
                toolbar(list),
                Gaps.h12,
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = _calcCols(constraints.maxWidth);
                      const spacing = AppSpacing.sm;
                      final itemWidth =
                          (constraints.maxWidth - spacing * (cols - 1)) / cols;

                      Widget card(InstanceView v, {required bool forReorder}) => SizedBox(
                        width: itemWidth,
                        child: Wiggle(
                          enabled: inReorder,
                          phaseSeed: (v.id.hashCode % 628) / 100.0,
                          child: forReorder
                              ? buildTile(v, disableTap: true)
                              : buildTileWithLongPress(v),
                        ),
                      );

                      return ReorderGrid<InstanceView>(
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
                          ref.read(instancesWorkingOrderProvider.notifier).setAll(newIds);
                          if (!_dragReportedDirty) {
                            _dragReportedDirty = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                ref.read(instancesReorderDirtyProvider.notifier).state = true;
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