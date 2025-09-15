import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:cartridge/app/presentation/widgets/badge/badge.dart';
import 'package:cartridge/app/presentation/widgets/editable_header_title.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/shell_open.dart';
import 'package:cartridge/core/utils/workshop_util.dart';
import 'package:cartridge/features/cartridge/instances/instances.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/steam/steam.dart';
import 'package:cartridge/features/web_preview/web_preview.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';


class InstanceDetailPage extends ConsumerStatefulWidget {
  final String instanceId;
  final String instanceName;
  final VoidCallback onBack;

  const InstanceDetailPage({
    super.key,
    required this.instanceId,
    required this.instanceName,
    required this.onBack,
  });

  @override
  ConsumerState<InstanceDetailPage> createState() => _InstanceDetailPageState();
}

class _InstanceDetailPageState extends ConsumerState<InstanceDetailPage> {
  late final TextEditingController _nameController;
  final _moreFlyout = FlyoutController();
  final _headerMoreFlyout = FlyoutController();

  InstanceImage? _stickyImage;

  String _colFromSort(InstanceSortKey k) {
    switch (k) {
      case InstanceSortKey.name:
        return 'displayName';
      case InstanceSortKey.version:
        return 'version';
      case InstanceSortKey.enabled:
        return 'enabled';
      case InstanceSortKey.favorite:
        return 'favorite';
      case InstanceSortKey.enabledPreset:
        return 'enabledPreset';
      case InstanceSortKey.enabledByPresetCount:
      case InstanceSortKey.missing:
      case InstanceSortKey.updatedAt:
      case InstanceSortKey.lastSyncAt:
        return 'displayName';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.instanceName);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ui = ref.read(instanceDetailPageControllerProvider(widget.instanceId).notifier);
      ui.cancelEditName();
      ui.setSearch('');
      ui.setDisplayName(widget.instanceName);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _moreFlyout.dispose();
    _headerMoreFlyout.dispose();
    super.dispose();
  }

  bool _presetPickerOpen = false;

  Future<bool> _confirmDelete(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(loc.instance_delete_title),
        content: Text(loc.instance_delete_message),
        actions: [
          Button(child: Text(loc.common_cancel), onPressed: () => Navigator.pop(ctx, false)),
          FilledButton(child: Text(loc.common_delete), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _openImagePicker(String seedName) async {
    final uiState = ref.read(instanceDetailPageControllerProvider(widget.instanceId));
    final seed = (seedName.trim().isEmpty) ? uiState.displayName : seedName;

    final res = await showInstanceImagePickerDialog(
      context,
      seedForDefault: seed,
      initialSpriteIndex: uiState.image?.maybeMap(sprite: (s) => s.index, orElse: () => null),
      initialUserFilePath: uiState.image?.maybeMap(userFile: (u) => u.path, orElse: () => null),
    );
    if (!mounted || res == null) return;

    final ctrl = ref.read(instanceDetailControllerProvider(widget.instanceId).notifier);
    InstanceImage? picked;
    if (res is PickSprite) {
      picked = InstanceImage.sprite(index: res.index);
      await ctrl.setImageToSprite(widget.instanceId, res.index);
    } else if (res is PickUserFile) {
      picked = InstanceImage.userFile(path: res.path, fit: res.fit);
      await ctrl.setImageToUserFile(widget.instanceId, res.path, fit: res.fit);
    } else if (res is PickClear) {
      picked = null;
      await ctrl.clearImage(widget.instanceId);
    }

    final uiCtrl = ref.read(instanceDetailPageControllerProvider(widget.instanceId).notifier);
    if (mounted) {
      uiCtrl.setUiImage(picked);
      setState(() => _stickyImage = picked);
    }
  }

  Future<void> _pickAndAddPresets() async {
    if (_presetPickerOpen) return;
    _presetPickerOpen = true;
    try {
      final app = ref.read(instanceDetailControllerProvider(widget.instanceId));
      if (!app.hasValue) return;
      final inst = app.requireValue;
      final current = inst.appliedPresets.map((p) => p.presetId).toSet();

      final sel = await showModPresetPickerDialog(context, initialSelected: current);
      if (sel == null) return;

      final refs = sel.map((id) => AppliedPresetRef(presetId: id)).toList(growable: false);
      await ref.read(instanceDetailControllerProvider(widget.instanceId).notifier).setPresetIds(refs);
    } finally {
      _presetPickerOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(instanceDetailControllerProvider(widget.instanceId));
    final ui = ref.watch(instanceDetailPageControllerProvider(widget.instanceId));
    final uiCtrl = ref.read(instanceDetailPageControllerProvider(widget.instanceId).notifier);

    final rows = ref.watch(instanceVisibleResolvedProvider(widget.instanceId));
    final tableCtrl = ref.watch(instanceTableCtrlProvider(widget.instanceId));
    final presetFilters = ref.watch(presetQuickFiltersProvider(widget.instanceId));
    final loc = AppLocalizations.of(context);
    final metaPresetFilters = <UTQuickFilter<ModView>>[
      UTQuickFilter<ModView>(id: 'mpt_has', label: loc.instance_quickfilter_has_preset, test: (r) => r.enabledByPresets.isNotEmpty),
      UTQuickFilter<ModView>(id: 'mpt_none', label: loc.instance_quickfilter_no_preset, test: (r) => r.enabledByPresets.isEmpty),
    ];
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    ref.listen<AsyncValue<InstanceView>>(
      instanceDetailControllerProvider(widget.instanceId),
          (prev, next) {
        next.whenData((app) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && app.image != null) {
              setState(() => _stickyImage = app.image!);
            }
            final cur = ref.read(instanceDetailPageControllerProvider(widget.instanceId));
            final wantName = app.name;
            final wantImg = app.image;
            if (cur.displayName != wantName || cur.image != wantImg) {
              uiCtrl.hydrate(name: wantName, image: wantImg);
            }
          });
        });
      },
    );

    InstanceImage? pickHeaderImage() {
      if (appAsync.isLoading && ui.image == null && _stickyImage != null) {
        return _stickyImage;
      }
      return ui.image;
    }

    final List<UTColumnSpec> columns = [
      UTColumnSpec(
        id: 'favorite',
        title: loc.mod_table_header_favorite,
        header: Padding(padding: const EdgeInsets.all(8), child: Icon(FluentIcons.heart, size: 16, color: fTheme.accentColor)),
        width: UTWidth.px(52),
        sortable: true,
        resizable: false,
        tooltip: loc.mod_table_header_favorite,
      ),
      UTColumnSpec(id: 'displayName', title: loc.mod_table_header_name, width: UTWidth.flex(3), sortable: true, minPx: 120),
      UTColumnSpec(
        id: 'enabledPreset',
        title: loc.instance_table_header_enabled_preset,
        width: UTWidth.flex(1),
        sortable: true,
        minPx: 120,
        hideBelowPx: AppBreakpoints.sm,
      ),
      UTColumnSpec(id: 'version', title: loc.mod_table_header_version, width: UTWidth.px(80), sortable: true, hideBelowPx: AppBreakpoints.sm + 80),
      UTColumnSpec(id: 'enabled', title: loc.mod_table_header_enabled, width: UTWidth.px(80), sortable: true),
      UTColumnSpec(
        id: 'folder',
        title: loc.mod_table_header_folder,
        header: const Padding(padding: EdgeInsets.all(8), child: Icon(FluentIcons.open_folder_horizontal, size: 16)),
        width: UTWidth.px(52),
        sortable: false,
        resizable: false,
        tooltip: loc.mod_action_open_folder,
        hideBelowPx: AppBreakpoints.sm + 40,
      ),
    ];

    final Map<String, String> effectiveNameMap = {
      for (final r in rows)
        r.id: () {
          var name = r.displayName;
          if (r.modId.isNotEmpty) {
            final url = SteamUrls.workshopItem(r.modId);
            final previewAsync = ref.watch(webPreviewProvider(url));
            final title = previewAsync.maybeWhen(data: (p) => p?.title, orElse: () => null);
            final fromWeb = extractWorkshopModName(title);
            if (fromWeb != null && fromWeb.isNotEmpty) name = fromWeb;
          }
          return name;
        }(),
    };
    String nameOf(ModView r) => effectiveNameMap[r.id] ?? r.displayName;

    final comparators = <String, int Function(ModView, ModView)>{
      'displayName': (a, b) => nameOf(a).toLowerCase().compareTo(nameOf(b).toLowerCase()),
      'version': (a, b) => compareInstanceModView(InstanceSortKey.version, true, a, b),
      'enabled': (a, b) => compareInstanceModView(InstanceSortKey.enabled, true, a, b),
      'favorite': (a, b) => compareInstanceModView(InstanceSortKey.favorite, true, a, b),
      'enabledPreset': (a, b) => compareInstanceModView(InstanceSortKey.enabledPreset, true, a, b),
    };

    return LayoutBuilder(
      builder: (ctx, cons) {
        final bodyHeight = cons.maxHeight - ContentLayout.pagePadding.vertical;

        final pickedHeaderImage = pickHeaderImage();
        final showSkeleton = pickedHeaderImage == null;
        final optionsAsync = ref.watch(optionPresetsControllerProvider);

        return ScaffoldPage(
          header: ContentHeaderBar.backImageCustom(
            onBack: () {
              uiCtrl.cancelEditName();
              uiCtrl.setSearch('');
              widget.onBack();
            },
            titleWidget: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditableHeaderTitle(
                    title: appAsync.asData?.value.name ?? widget.instanceName,
                    editing: ui.editingName,
                    onStartEdit: uiCtrl.startEditName,
                    onCancel: uiCtrl.cancelEditName,
                    onSave: uiCtrl.saveName,
                    hintText: loc.instance_create_name_placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Gaps.h4,
                  OptionPresetInlineControl(
                    optionsAsync: optionsAsync,
                    selectedId: appAsync.asData?.value.optionPresetId,
                    onChanged: (next) {
                      ref.read(instanceDetailControllerProvider(widget.instanceId).notifier).setOptionPreset(next);
                    },
                  ),
                ],
              ),
            ),
            leadingEditable: showSkeleton
                ? _HeaderImageSkeleton(size: 80, radius: 10, onTap: () => _openImagePicker(ui.displayName))
                : EditableImageThumb(
              tooltip: loc.instance_image_change,
              image: pickedHeaderImage,
              seed: ui.displayName,
              size: 80,
              radius: 10,
              onTap: () => _openImagePicker(ui.displayName),
            ),
            actions: [
              Tooltip(
                message: loc.common_play,
                child: FilledButton(
                  style: ButtonStyle(backgroundColor: WidgetStateProperty.all(FluentTheme.of(context).accentColor)),
                  onPressed: () async {
                    try {
                      await ref.read(instancePlayServiceProvider).playByInstanceId(widget.instanceId);
                    } catch (e) {
                      if (!context.mounted) return;
                      UiFeedback.error(context, content: loc.instance_play_failed_body);
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(FluentIcons.play_solid, size: 14),
                      Gaps.w6,
                      Text(loc.common_play),
                    ],
                  ),
                ),
              ),
              Gaps.w6,
              FlyoutTarget(
                controller: _headerMoreFlyout,
                child: IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () {
                    _headerMoreFlyout.showFlyout(
                      placementMode: FlyoutPlacementMode.bottomRight,
                      builder: (ctx) => MenuFlyout(
                        color: FluentTheme.of(context).scaffoldBackgroundColor,
                        items: [
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.edit),
                            text: Text(loc.common_edit),
                            onPressed: () async {
                              Flyout.of(ctx).close();

                              final app = ref.read(instanceDetailControllerProvider(widget.instanceId));
                              if (!app.hasValue) return;
                              final view = app.requireValue;

                              final res = await showEditInstanceDialog(
                                context,
                                initialName: view.name,
                                initialPresetIds: view.appliedPresets.map((e) => e.presetId).toSet(),
                                initialOptionPresetId: view.optionPresetId,
                              );
                              if (res == null) return;

                              final uiCtrl = ref.read(instanceDetailPageControllerProvider(widget.instanceId).notifier);
                              bool changed = false;

                              final newName = res.name.trim();
                              if (newName.isNotEmpty && newName != view.name) {
                                await uiCtrl.saveName(newName);
                                changed = true;
                              }

                              if (res.optionPresetId != view.optionPresetId) {
                                await uiCtrl.setOptionPreset(res.optionPresetId);
                                changed = true;
                              }

                              final nextRefs = res.presetIds.map((id) => AppliedPresetRef(presetId: id)).toList(growable: false);
                              String sigLabels(List<AppliedPresetLabelView> a) => a.map((e) => e.presetId).join('|');
                              String sigIds(List<String> a) => a.join('|');
                              final curSig = sigLabels(view.appliedPresets);
                              final nextSig = sigIds(res.presetIds);
                              if (curSig != nextSig) {
                                await uiCtrl.setPresetIds(nextRefs);
                                changed = true;
                              }

                              if (!context.mounted) return;
                              if (changed) {
                                UiFeedback.success(context, title: loc.common_saved, content: loc.common_changes_applied);
                              }
                            },
                          ),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.download),
                            text: Text(loc.common_export),
                            // TODO
                            onPressed: () => UiFeedback.info(context, title: loc.common_export, content: loc.common_coming_soon),
                          ),
                          const MenuFlyoutSeparator(),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.delete),
                            text: Text(loc.common_delete),
                            onPressed: () async {
                              final ok = await _confirmDelete(context);
                              if (!ok) return;
                              await ref.read(instanceDetailPageControllerProvider(widget.instanceId).notifier).deleteInstance();
                              if (!mounted) return;
                              widget.onBack();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          content: ContentShell(
            scrollable: false,
            child: SizedBox(
              height: bodyHeight,
              child: appAsync.when(
                loading: () => const Center(child: ProgressRing()),
                error: (err, _) => EmptyState.withDefault404(
                  title: loc.instance_load_failed,
                ),
                data: (app) {
                  if (_nameController.text != app.name) {
                    _nameController.text = app.name;
                  }

                  return UTTableFrame<ModView>(
                    columns: columns,
                    rows: rows,
                    controller: tableCtrl,

                    // 행높이(comfortable 기준), compact/tile 별도 지정
                    rowHeight: 52,
                    compactRowHeight: 36,
                    tileRowHeight: 64,

                    rowBaseBackground: (ctx, r) {
                      if (r.isMissing) {
                        return sem.danger.bg.withAlpha(16);
                      }
                      return null;
                    },
                    selectionEnabled: true,
                    reserveLeading: true,
                    rowSelected: (r) => uiCtrl.isSelected(r.id),
                    onRowCheckboxChanged: (r, v) => uiCtrl.setRowSelected(r.id, v),
                    onToggleAllInView: (want, visible) {
                      for (final r in visible) {
                        uiCtrl.setRowSelected(r.id, want);
                      }
                    },
                    initialSortColumnId: _colFromSort(app.sortKey ?? InstanceSortKey.name),
                    initialAscending: app.ascending ?? true,
                    comparators: comparators,
                    headerTrailing: UTHeaderRefreshButton(
                      tooltip: loc.common_refresh,
                      onRefresh: () async {
                        await uiCtrl.refreshFromStore();
                        if (!context.mounted) return;
                        UiFeedback.success(context, title: loc.common_refresh, content: loc.mod_table_reloaded);
                      },
                    ),
                    reserveTrailing: true,
                    rowTrailing: (rowCtx, r) => FlyoutTarget(
                      controller: _moreFlyout,
                      child: IconButton(
                        icon: const Icon(FluentIcons.more),
                        onPressed: () {
                          _moreFlyout.showFlyout(
                            barrierColor: Colors.transparent,
                            autoModeConfiguration: FlyoutAutoConfiguration(
                              preferredMode: FlyoutPlacementMode.topRight,
                            ),
                            builder: (ctx) {
                              final items = <MenuFlyoutItemBase>[];
                              if (r.isMissing) {
                                items.add(MenuFlyoutItem(
                                  leading: const Icon(FluentIcons.delete),
                                  text: Text(loc.mod_menu_remove),
                                  onPressed: () => uiCtrl.removeByKey(r.id),
                                ));
                              } else {
                                items.add(MenuFlyoutItem(
                                  leading: const Icon(FluentIcons.open_folder_horizontal),
                                  text: Text(loc.mod_menu_open_folder),
                                  onPressed: () => openFolder(r.installPath),
                                ));
                              }
                              if (r.modId.isNotEmpty) {
                                items.add(MenuFlyoutItem(
                                  leading: const Icon(FluentIcons.navigate_external_inline),
                                  text: Text(loc.mod_menu_open_page),
                                  onPressed: () async {
                                    await ref.read(isaacSteamLinksProvider).openIsaacWorkshopItem(r.modId);
                                    if (!ctx.mounted) return;
                                    Flyout.of(ctx).close();
                                  },
                                ));
                              }
                              return MenuFlyout(items: items, color: fTheme.scaffoldBackgroundColor);
                            },
                          );
                        },
                      ),
                    ),
                    cellBuilder: (ctx, r) => [
                      Tooltip(
                        message: r.favorite
                            ? loc.mod_favorite_tooltip_selected
                            : loc.mod_favorite_tooltip_unselected,
                        child: IconButton(
                          icon: Icon(r.favorite ? FluentIcons.heart_fill : FluentIcons.heart, size: 16, color: fTheme.accentColor),
                          onPressed: () => uiCtrl.toggleFavorite(r.id),
                        ),
                      ),
                      Builder(builder: (ctx) {
                        final vis     = UTColumnVisibility.of(ctx);
                        final tTheme  = UTTableTheme.of(ctx);
                        final density = tTheme.density;

                        final isTile         = density == UTTableDensity.tile;
                        final isComfortable  = density == UTTableDensity.comfortable;

                        final versionVisible        = vis?.isVisible('version')        ?? true;
                        final enabledPresetVisible  = vis?.isVisible('enabledPreset')  ?? true;

                        final isNarrowVersion = !versionVisible;
                        final isNarrowPreset  = !enabledPresetVisible;

                        final nameForRow = nameOf(r);

                        // enabledPreset → BadgeSpec 목록으로 변환 (한 번만 계산해 재사용)
                        final presetBadges = r.enabledByPresets.map((pid) {
                          final label = app.appliedPresets.firstWhere(
                                (e) => e.presetId == pid,
                            orElse: () => AppliedPresetLabelView(presetId: pid, presetName: pid),
                          ).presetName;
                          return BadgeSpec(label, accent2StatusOf(context, ref));
                        }).toList(growable: false);

                        // ── 밀도별 정책 ───────────────────────────────────────────────────────────
                        // tile:   숨겨지면 version + enabledPreset 모두 제목 아래
                        // comf.:  숨겨지면 enabledPreset만 제목 아래, version은 숨김
                        // compact:제목만 (둘 다 제목 아래로 X)
                        final showVersionUnderTitle =
                            (isTile || isComfortable ) && !versionVisible;

                        final showEnabledPresetUnderTitle =
                            !enabledPresetVisible && (isTile || isComfortable) && presetBadges.isNotEmpty;

                        return ModTitleCell(
                          key: ValueKey(r.id),
                          row: r,
                          displayName: nameForRow,
                          showVersionUnderTitle: showVersionUnderTitle,
                          placeholderFallback: 'M',
                          prewarmPreview: true,
                          isNarrowVersion: isNarrowVersion,
                          isNarrowPreset:  isNarrowPreset,
                          extraBadges: (row, ft) {
                            final out = <BadgeSpec>[];
                            if (showEnabledPresetUnderTitle) {
                              out.addAll(presetBadges);
                            }
                            return out;
                          },
                          onTapTitle: r.modId.isEmpty
                              ? null
                              : () async => ref.read(isaacSteamLinksProvider).openIsaacWorkshopItem(r.modId),
                        );
                      }),
                      BadgeStrip(
                        badges: r.enabledByPresets
                            .map((pid) {
                          final label = app.appliedPresets.firstWhere(
                                (e) => e.presetId == pid,
                            orElse: () => AppliedPresetLabelView(presetId: pid, presetName: pid),
                          ).presetName;
                          return BadgeSpec(label, accent2StatusOf(context, ref));
                        })
                            .toList(),
                      ),
                      Text(r.version),
                      ToggleSwitch(checked: r.enabled, onChanged: (v) => uiCtrl.setEnabled(r.id, v)),
                      r.isInstalled
                          ? Tooltip(
                        message: loc.mod_action_open_folder,
                        child: IconButton(
                          icon: const Icon(FluentIcons.open_folder_horizontal, size: 16),
                          onPressed: () => openFolder(r.installPath),
                        ),
                      )
                          : Tooltip(
                        message: loc.mod_action_delete_missing,
                        child: IconButton(
                          icon: Icon(FluentIcons.delete, size: 16, color: sem.danger.fg),
                          onPressed: () => uiCtrl.removeByKey(r.id),
                        ),
                      ),
                    ],
                    showSearch: true,
                    initialQuery: '',
                    searchHintText: loc.mod_search_placeholder,
                    stringify: (it) {
                      final tags = it.installedRef?.metadata.tags.join(' ') ?? '';
                      final ver = it.installedRef?.metadata.version ?? '';
                      final name = nameOf(it);
                      return '$name $ver ${it.id} $tags';
                    },
                    quickFilters: [
                      UTQuickFilter<ModView>(id: 'favorite', label: loc.mod_quickfilter_favorite, test: (r) => r.favorite),
                      UTQuickFilter<ModView>(id: 'installed', label: loc.mod_quickfilter_installed, test: (r) => r.isInstalled),
                      UTQuickFilter<ModView>(id: 'missing', label: loc.mod_quickfilter_missing, test: (r) => r.isMissing),
                      UTQuickFilter<ModView>(id: 'enabled', label: loc.mod_quickfilter_enabled, test: (r) => r.enabled),
                      ...metaPresetFilters,
                      ...presetFilters, // 프리셋 그룹은 Toolbar에서 sidebarOn일 때 자동 숨김
                    ],
                    quickFiltersAreAnd: true,
                    isPresetFilterId: (id) => id.startsWith('mp_'),
                    showFloatingSelectionBar: true,
                    canFavoriteOn: (m) => !m.favorite,
                    canFavoriteOff: (m) => m.favorite,
                    canEnable: (m) => !m.enabled && m.isInstalled,
                    canDisable: (m) => m.enabled,
                    onFavoriteOnSelected: (_) => uiCtrl.favoriteSelected(),
                    onFavoriteOffSelected: (_) => uiCtrl.unfavoriteSelected(),
                    onEnableSelected: (_) => uiCtrl.enableSelected(),
                    onDisableSelected: (_) => uiCtrl.disableSelected(),
                    onSharePlainSelected: (_) async {
                      final n = await uiCtrl.copySelectedNamesPlain();
                      if (!context.mounted) return;
                      if (n > 0) {
                        UiFeedback.success(context, title: loc.common_copied, content: '$n${loc.common_items_copied}');
                      } else if (n == 0) {
                        UiFeedback.warn(context, title: loc.common_copied, content: loc.common_nothing_selected);
                      } else {
                        UiFeedback.error(context, content: loc.common_copy_failed);
                      }
                    },
                    onShareMarkdownSelected: (_) async {
                      final n = await uiCtrl.copySelectedNamesMarkdown();
                      if (!context.mounted) return;
                      if (n > 0) {
                        UiFeedback.success(context, title: loc.common_copied, content: '$n${loc.common_items_copied}');
                      } else if (n == 0) {
                        UiFeedback.warn(context, title: loc.common_copied, content: loc.common_nothing_selected);
                      } else {
                        UiFeedback.error(context, content: loc.common_copy_failed);
                      }
                    },
                    onShareRichSelected: (_) async {
                      final n = await uiCtrl.copySelectedNamesRich();
                      if (!context.mounted) return;
                      if (n > 0) {
                        UiFeedback.success(context, title: loc.common_copied, content: '$n${loc.common_items_copied}');
                      } else if (n == 0) {
                        UiFeedback.warn(context, title: loc.common_copied, content: loc.common_nothing_selected);
                      } else {
                        UiFeedback.error(context, content: loc.common_copy_failed);
                      }
                    },
                    initialSidebarOn: true,
                    alwaysShowLeftSidebar: false,
                    leftSidebar: InstancePresetSidebar(
                      instanceId: widget.instanceId,
                      presets: app.appliedPresets,
                      onAddPresets: _pickAndAddPresets,
                    ),
                    leftSidebarWidth: 240,
                    initialDensity: UTTableDensity.tile,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}


class _HeaderImageSkeleton extends StatelessWidget {
  const _HeaderImageSkeleton({
    required this.size,
    required this.radius,
    required this.onTap,
  });

  final double size;
  final double radius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: fTheme.resources.controlFillColorSecondary),
          alignment: Alignment.center,
          child: const ProgressRing(),
        ),
      ),
    );
  }
}