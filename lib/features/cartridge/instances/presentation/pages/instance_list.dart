import 'dart:async';
import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/badge.dart';
import 'package:cartridge/app/presentation/widgets/search_toolbar.dart';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/sprite_sheet.dart' as ss;
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/wiggle.dart';
import 'package:cartridge/features/cartridge/instances/application/instances_controller.dart';
import 'package:cartridge/features/cartridge/instances/domain/models/instance_view.dart';
import 'package:cartridge/features/cartridge/instances/presentation/controllers/instances_page_controller.dart';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/create_instance_dialog.dart';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/list_tiles.dart';
import 'package:cartridge/features/cartridge/option_presets/application/option_presets_controller.dart';
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
  Timer? _idleTimer;
  static const _idleDuration = Duration(minutes: 1);
  bool _dragReportedDirty = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    ss.SpriteSheetLoader.load('assets/images/instance_thumbs.png');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _normalScroll.dispose();
    _editScroll.dispose();
    _searchCtrl.dispose();
    _idleTimer?.cancel();
    super.dispose();
  }

  void _startIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleDuration, () async {
      if (!ref.read(instancesReorderModeProvider)) return;
      final ids   = ref.read(instancesWorkingOrderProvider);
      final dirty = ref.read(instancesReorderDirtyProvider);
      if (dirty) {
        final result = await ref.read(instancesControllerProvider.notifier).reorderInstances(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, '저장됨', '변경 내용이 저장되었습니다.'),
          notFound: (_, __)      async => UiFeedback.warn(context, '대상 없음', '저장할 인스턴스를 찾지 못했습니다.'),
          invalid:  (_, __, ___) async => UiFeedback.error(context, '저장 실패', '정렬 데이터가 올바르지 않습니다.'),
          conflict: (_, __)      async => UiFeedback.warn(context, '충돌', '다른 변경과 충돌했습니다. 다시 시도하세요.'),
          failure:  (_, __, ___) async => UiFeedback.error(context, '오류', '정렬 저장 중 오류가 발생했습니다.'),
        );
      }
      ref.read(instancesReorderModeProvider.notifier).state  = false;
      ref.read(instancesReorderDirtyProvider.notifier).state = false;
      _dragReportedDirty = false;
      _idleTimer?.cancel();
    });
  }

  void _bumpIdleTimer() {
    if (ref.read(instancesReorderModeProvider)) _startIdleTimer();
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
      }
    });
  }

  Future<void> _goDetail(String id, String name) async {
    widget.onSelect(id, name);
  }

  int _calcCols(double maxW) => maxW >= AppBreakpoints.md ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    ref.watch(optionPresetsControllerProvider);

    final listAsync = ref.watch(orderedInstancesForUiProvider);
    final inReorder = ref.watch(instancesReorderModeProvider);
    final dirty     = ref.watch(instancesReorderDirtyProvider);
    final q         = ref.watch(instancesQueryProvider);

    return ScaffoldPage(
        header: const ContentHeaderBar.none(),
        content: ContentShell(
          scrollable: false,
          child: listAsync.when(
            loading: () => const Center(child: ProgressRing()),
            error: (err, st) => Center(child: Text('인스턴스 로딩 실패: $err')),
            data: (List<InstanceView> list) {
              if (inReorder) {
                final working = ref.read(instancesWorkingOrderProvider);
                final curIds  = list.map((e) => e.id).toList(growable: false);
                final next = <String>[
                  ...working.where(curIds.contains),
                  ...curIds.where((id) => !working.contains(id)),
                ];
                if (next.length != working.length || !const ListEquality().equals(next, working)) {
                  ref.read(instancesWorkingOrderProvider.notifier).setAll(next);
                  ref.read(instancesReorderDirtyProvider.notifier).state = true;
                }
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
                  notFound: (_, __) async {}, invalid:  (_, __, ___) async {},
                  conflict: (_, __) async {}, failure:  (_, __, ___) async {},
                );
              }

              // ── SearchToolbar (액션 주입) ─────────────────────────────
              final toolbar = SearchToolbar(
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
                      ref.read(instancesWorkingOrderProvider.notifier).syncFrom(list);
                      _idleTimer?.cancel();
                      _dragReportedDirty = false;
                    },
                    child: const Text('취소'),
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
                          UiFeedback.success(context, '저장됨', '변경 내용이 저장되었습니다.');
                          _dragReportedDirty = false;
                        },
                        notFound: (_, __)      async => UiFeedback.warn(context, '대상 없음', '저장할 인스턴스를 찾지 못했습니다.'),
                        invalid:  (_, __, ___) async => UiFeedback.error(context, '저장 실패', '정렬 데이터가 올바르지 않습니다.'),
                        conflict: (_, __)      async => UiFeedback.warn(context, '충돌', '다른 변경과 충돌했습니다. 다시 시도해 주세요.'),
                        failure:  (_, __, ___) async => UiFeedback.error(context, '오류', '정렬 저장 중 오류가 발생했습니다.'),
                      );
                      _idleTimer?.cancel();
                    }
                        : null,
                    child: const Text('저장'),
                  ),
                ]
                    : [
                  Button(
                    onPressed: createFlow,
                    child: Row(
                      children: [
                        const Icon(
                          FluentIcons.add,
                          size: 12,
                        ),
                        Gaps.w4,
                        Text(loc.instance_create_button),
                      ],
                    ),
                  ),
                  Gaps.w6,
                  Button(
                    onPressed: () {
                      if (q.trim().isNotEmpty) {
                        UiFeedback.warn(context, '정렬 편집 불가', '검색 중에는 정렬을 시작할 수 없습니다.');
                        return;
                      }
                      ref.read(instancesReorderModeProvider.notifier).state  = true;
                      ref.read(instancesReorderDirtyProvider.notifier).state = false;
                      ref.read(instancesWorkingOrderProvider.notifier).syncFrom(list);
                      _dragReportedDirty = false;
                      _startIdleTimer();
                    },
                    child: const Row(
                      children: [
                        Icon(
                          FluentIcons.edit,
                          size: 12,
                        ),
                        Gaps.w4,
                        Text('편집'),
                      ],
                    ),
                  ),
                ],
              );

              if (list.isEmpty) {
                return Column(
                  children: [
                    toolbar,
                    Gaps.h12,
                    Expanded(
                      child: Center(
                        child: EmptyState.withDefault404(
                          title: loc.instance_empty_message,
                          primaryLabel: loc.instance_create_button,
                          onPrimary: createFlow,
                        )
                      ),
                    ),
                  ],
                );
              }

              InstanceBadgeCardTile buildTile(InstanceView v, {bool disableTap = false}) {
                final enabledLabel = loc.instance_enabled_mods(v.enabledCount, v.appliedPresets.length);
                final badges = <BadgeSpec>[BadgeSpec(enabledLabel, sem.info)];

                if (v.optionPresetId != null && v.optionPresetId is String) {
                  final optionPreset = ref.read(optionPresetByIdProvider(v.optionPresetId as String));
                  if (optionPreset?.useRepentogon == true) {
                    badges.add(BadgeSpec(loc.option_use_repentogon_label, sem.danger));
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
                    _bumpIdleTimer();
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
                          text: const Text('정렬 편집'),
                          leading: const Icon(FluentIcons.drag_object),
                          onPressed: () {
                            if (q.trim().isNotEmpty) {
                              UiFeedback.warn(context, '정렬 편집 불가', '검색 중에는 정렬을 시작할 수 없습니다.');
                              return;
                            }
                            ref.read(instancesReorderModeProvider.notifier).state  = true;
                            ref.read(instancesReorderDirtyProvider.notifier).state = false;
                            ref.read(instancesWorkingOrderProvider.notifier).syncFrom(list);
                            _dragReportedDirty = false;
                            _startIdleTimer();
                          },
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
                final enabledLabel = loc.instance_enabled_mods(v.enabledCount, v.appliedPresets.length);
                final badges = <BadgeSpec>[BadgeSpec(enabledLabel, sem.info)];
                if (v.optionPresetId != null && v.optionPresetId is String) {
                  final optionPreset = ref.read(optionPresetByIdProvider(v.optionPresetId as String));
                  if (optionPreset?.useRepentogon == true) {
                    badges.add(BadgeSpec(loc.option_use_repentogon_label, sem.danger));
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
                        text: const Text('정렬 편집'),
                        leading: const Icon(FluentIcons.drag_object),
                        onPressed: () {
                          if (q.trim().isNotEmpty) {
                            UiFeedback.warn(context, '정렬 편집 불가', '검색 중에는 정렬을 시작할 수 없습니다.');
                            return;
                          }
                          ref.read(instancesReorderModeProvider.notifier).state  = true;
                          ref.read(instancesReorderDirtyProvider.notifier).state = false;
                          ref.read(instancesWorkingOrderProvider.notifier).syncFrom(list);
                          _dragReportedDirty = false;
                          _startIdleTimer();
                        },
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
                  onLongPress: () {
                    if (inReorder) return;
                    if (q.trim().isNotEmpty) return;
                    ref.read(instancesReorderModeProvider.notifier).state  = true;
                    ref.read(instancesReorderDirtyProvider.notifier).state = false;
                    ref.read(instancesWorkingOrderProvider.notifier).syncFrom(list);
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

                        Widget card(InstanceView v) => SizedBox(
                          width: itemWidth,
                          child: Wiggle(
                            enabled: inReorder,
                            phaseSeed: (v.id.hashCode % 628) / 100.0, // 0..6.28
                            child: inReorder
                                ? buildTile(v, disableTap: true)
                                : buildTileWithLongPress(v),
                          ),
                        );

                        if (inReorder) {
                          final children = [
                            for (final v in list)
                              RepaintBoundary(
                                key: ValueKey(v.id),
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
                              final idsBefore = ref.read(instancesWorkingOrderProvider);
                              final fake  = idsBefore.map((e) => _Fake(id: e)).toList();
                              final after = reorderFn(fake).cast<_Fake>().map((e) => e.id).toList();

                              ref.read(instancesWorkingOrderProvider.notifier).setAll(after);
                              if (!_dragReportedDirty) {
                                _dragReportedDirty = true;
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted) {
                                    ref.read(instancesReorderDirtyProvider.notifier).state = true;
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
