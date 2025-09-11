import 'dart:async';
import 'package:cartridge/theme/theme.dart';
import 'package:collection/collection.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/widgets/badge.dart';
import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:cartridge/app/presentation/widgets/list_tiles.dart';
import 'package:cartridge/app/presentation/widgets/search_toolbar.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/core/result.dart';
import 'package:cartridge/core/utils/wiggle.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/l10n/app_localizations.dart';

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
      if (dirty) {
        final result = await ref.read(modPresetsControllerProvider.notifier).reorderModPresets(ids);
        await result.when(
          ok:       (_, __, ___) async => UiFeedback.success(context, '저장됨', '변경 내용이 저장되었습니다.'),
          notFound: (_, __)      async => UiFeedback.warn(context, '대상 없음', '저장할 프리셋을 찾지 못했습니다.'),
          invalid:  (_, __, ___) async => UiFeedback.error(context, '저장 실패', '정렬 데이터가 올바르지 않습니다.'),
          conflict: (_, __)      async => UiFeedback.warn(context, '충돌', '다른 변경과 충돌했습니다. 다시 시도하세요.'),
          failure:  (_, __, ___) async => UiFeedback.error(context, '오류', '정렬 저장 중 오류가 발생했습니다.'),
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
    final sem = ref.watch(themeSemanticsProvider);

    final listAsync = ref.watch(orderedModPresetsForUiProvider);
    final inReorder = ref.watch(modPresetsReorderModeProvider);
    final dirty     = ref.watch(modPresetsReorderDirtyProvider);
    final q         = ref.watch(modPresetsQueryProvider);


    return ScaffoldPage(
      header: const ContentHeaderBar.none(),
      content: ContentShell(
        scrollable: false,
        child: listAsync.when(
          loading: () => const Center(child: ProgressRing()),
          error: (err, st) => Center(child: Text('프리셋 로딩 실패: $err')),
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

            // ── SearchToolbar(actions:) ──
            final toolbar = SearchToolbar(
              controller: _searchCtrl,
              placeholder: loc.mod_preset_search_placeholder,
              onChanged: _onSearchChanged,
              enabled: !inReorder,
              padding: EdgeInsetsGeometry.all(0),
              actions: inReorder
                  ? [
                Button(
                  onPressed: () {
                    ref.read(modPresetsReorderModeProvider.notifier).state  = false;
                    ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                    ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(list);
                    _idleTimer?.cancel();
                    _dragReportedDirty = false;
                  },
                  child: const Text('취소'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: dirty
                      ? () async {
                    final ids = ref.read(modPresetsWorkingOrderProvider);
                    final result = await ref.read(modPresetsControllerProvider.notifier).reorderModPresets(ids);
                    await result.when(
                      ok:       (_, __, ___) async {
                        ref.read(modPresetsReorderModeProvider.notifier).state  = false;
                        ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                        UiFeedback.success(context, '저장됨', '변경 내용이 저장되었습니다.');
                        _dragReportedDirty = false;
                      },
                      notFound: (_, __)      async => UiFeedback.warn(context, '대상 없음', '저장할 프리셋을 찾지 못했습니다.'),
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
                      Text(loc.mod_preset_create_button),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Button(
                  onPressed: () {
                    if (q.trim().isNotEmpty) {
                      UiFeedback.warn(context, '정렬 편집 불가', '검색 중에는 정렬을 시작할 수 없습니다.');
                      return;
                    }
                    ref.read(modPresetsReorderModeProvider.notifier).state  = true;
                    ref.read(modPresetsReorderDirtyProvider.notifier).state = false;
                    ref.read(modPresetsWorkingOrderProvider.notifier).syncFrom(list);
                    _dragReportedDirty = false;
                    _startIdleTimer();
                  },
                  child: const Row(
                    children: [
                      Icon(
                        FluentIcons.edit,
                        size: 12,
                      ),
                      SizedBox(width: 4),
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
                  SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: Center(
                      child: EmptyState.withDefault404(
                        title: '등록된 프리셋이 없습니다',
                        primaryLabel: '새 프리셋 만들기',
                        onPrimary: createFlow, // 기존 함수 연결
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
                badges: [BadgeSpec(enabledLabel, sem.info)],
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
                        text: const Text('정렬 편집'),
                        leading: const Icon(FluentIcons.drag_object),
                        onPressed: () {
                          if (q.trim().isNotEmpty) {
                            UiFeedback.warn(context, '정렬 편집 불가', '검색 중에는 정렬을 시작할 수 없습니다.');
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

            // 타일
            BadgeCardTile buildInnerTile(ModPresetView v) {
              final enabledLabel = loc.mod_preset_enabled_mods(v.enabledCount);
              final badges = <BadgeSpec>[BadgeSpec(enabledLabel, sem.info)];
              return BadgeCardTile(
                title: v.name,
                badges: badges,
                onTap: () => _goDetail(v.key, v.name),
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
                        await ref.read(modPresetsControllerProvider.notifier).clone(v.key,
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
                SizedBox(height: AppSpacing.md),
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
                          phaseSeed: (v.key.hashCode % 628) / 100.0, // 0..6.28
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
