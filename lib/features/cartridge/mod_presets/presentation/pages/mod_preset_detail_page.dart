import 'dart:async';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/widgets/editable_header_title.dart';
import 'package:cartridge/app/presentation/widgets/ui_feedback.dart';
import 'package:cartridge/app/presentation/widgets/ut/ut_table.dart';
import 'package:cartridge/core/service_providers.dart';
import 'package:cartridge/core/utils/shell_open.dart';
import 'package:cartridge/core/utils/workshop_util.dart';
import 'package:cartridge/features/cartridge/mod_presets/mod_presets.dart';
import 'package:cartridge/features/isaac/mod/isaac_mod.dart';
import 'package:cartridge/features/steam/domain/steam_app_urls.dart';
import 'package:cartridge/features/web_preview/application/web_preview_providers.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';


class ModPresetDetailPage extends ConsumerStatefulWidget {
  final String presetId;
  final String presetName;
  final VoidCallback onBack;

  const ModPresetDetailPage({
    super.key,
    required this.presetId,
    required this.presetName,
    required this.onBack,
  });

  @override
  ConsumerState<ModPresetDetailPage> createState() => _ModPresetDetailPageState();
}

class _ModPresetDetailPageState extends ConsumerState<ModPresetDetailPage> {

  late final TextEditingController _nameController;
  final _moreFlyout = FlyoutController();
  final _headerMoreFlyout = FlyoutController();
  final UTTableController<ModView> _tableCtrl = UTTableController<ModView>(initialQuery: '');

  String _colFromSort(ModSortKey k) {
    switch (k) {
      case ModSortKey.name:
        return 'displayName';
      case ModSortKey.version:
        return 'version';
      case ModSortKey.enabled:
        return 'enabled';
      case ModSortKey.favorite:
        return 'favorite';
      case ModSortKey.enabledPreset:
      case ModSortKey.missing:
      case ModSortKey.updatedAt:
      case ModSortKey.lastSyncAt:
        return 'displayName';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.presetName);
    Future.microtask(() {
      final ui = ref.read(modPresetDetailPageControllerProvider(widget.presetId).notifier);
      ui.cancelEditName();
      ui.setSearch('');
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tableCtrl.dispose();
    _moreFlyout.dispose();
    _headerMoreFlyout.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ContentDialog(
        title: Text(loc.mod_preset_delete_title),
        content: Text(loc.mod_preset_delete_message),
        actions: [
          Button(child: Text(loc.common_cancel), onPressed: () => Navigator.pop(ctx, false)),
          FilledButton(child: Text(loc.common_delete), onPressed: () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final appAsync = ref.watch(modPresetDetailControllerProvider(widget.presetId));
    final ui = ref.watch(modPresetDetailPageControllerProvider(widget.presetId));
    final uiCtrl = ref.read(modPresetDetailPageControllerProvider(widget.presetId).notifier);

    final rows = ref.watch(modPresetVisibleResolvedProvider(widget.presetId));
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);

    final List<UTColumnSpec> columns = [
      UTColumnSpec(
        id: 'favorite',
        title: loc.mod_table_header_favorite,
        header: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(FluentIcons.heart, size: 16, color: fTheme.accentColor),
        ),
        width: UTWidth.px(52),
        sortable: true,
        resizable: false,
        tooltip: loc.mod_table_header_favorite,
      ),
      UTColumnSpec(
        id: 'displayName',
        title: loc.mod_table_header_name,
        width: UTWidth.flex(3),
        sortable: true,
        minPx: 120,
      ),
      UTColumnSpec(id: 'version', title: loc.mod_table_header_version, width: UTWidth.px(100), sortable: true, hideBelowPx: AppBreakpoints.sm + 80),
      UTColumnSpec(id: 'enabled', title: loc.mod_table_header_enabled, width: UTWidth.px(100), sortable: true),
      UTColumnSpec(
        id: 'folder',
        title: loc.mod_table_header_folder,
        header: const Padding(padding: EdgeInsets.all(8), child: Icon(FluentIcons.open_folder_horizontal, size: 16)),
        width: UTWidth.px(52),
        sortable: false,
        resizable: false,
        tooltip: loc.mod_action_open_folder,
        hideBelowPx: AppBreakpoints.md,
      ),
    ];

    // 이 빌드 스코프에서 웹 타이틀 기반 표시이름 캐시
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
      'version': (a, b) => compareModView(ModSortKey.version, true, a, b),
      'enabled': (a, b) => compareModView(ModSortKey.enabled, true, a, b),
      'favorite': (a, b) => compareModView(ModSortKey.favorite, true, a, b),
    };

    return LayoutBuilder(
      builder: (ctx, cons) {
        final bodyHeight = cons.maxHeight - ContentLayout.pagePadding.vertical;

        return ScaffoldPage(
          header: ContentHeaderBar.backCustom(
            onBack: () {
              uiCtrl.cancelEditName();
              uiCtrl.setSearch('');
              widget.onBack();
            },
            titleWidget: EditableHeaderTitle(
              title: appAsync.asData?.value.name ?? widget.presetName,
              editing: ui.editingName,
              onStartEdit: uiCtrl.startEditName,
              onCancel: uiCtrl.cancelEditName,
              onSave: uiCtrl.saveName,
              hintText: loc.mod_preset_create_name_placeholder,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              FlyoutTarget(
                controller: _headerMoreFlyout,
                child: IconButton(
                  icon: const Icon(FluentIcons.more),
                  onPressed: () {
                    _headerMoreFlyout.showFlyout(
                      placementMode: FlyoutPlacementMode.bottomRight,
                      builder: (ctx) => MenuFlyout(
                        color: fTheme.scaffoldBackgroundColor,
                        items: [
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.edit),
                            text: Text(loc.mod_preset_edit_title),
                            onPressed: () async {
                              Flyout.of(ctx).close();
                              final cur = ref.read(modPresetDetailControllerProvider(widget.presetId));
                              final currentName = cur.value?.name ?? widget.presetName;
                              final newName = await showEditPresetNameDialog(context, initialName: currentName);
                              if (newName == null) return;
                              final trimmed = newName.trim();
                              if (trimmed.isEmpty || trimmed == currentName.trim()) return;
                              await ref.read(modPresetDetailPageControllerProvider(widget.presetId).notifier).saveName(trimmed);
                              if (!context.mounted) return;
                              UiFeedback.success(
                                context,
                                title: loc.common_saved,
                                content: loc.mod_preset_rename_success_body,
                              );
                            },
                          ),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.download),
                            text: Text(loc.common_export),
                            // TODO
                            onPressed: () => UiFeedback.info(
                              context,
                              title: loc.common_export,
                              content: loc.common_coming_soon,
                            ),
                          ),
                          const MenuFlyoutSeparator(),
                          MenuFlyoutItem(
                            leading: const Icon(FluentIcons.delete),
                            text: Text(loc.common_delete),
                            onPressed: () async {
                              final ok = await _confirmDelete(context);
                              if (!ok) return;
                              await ref.read(modPresetDetailPageControllerProvider(widget.presetId).notifier).deletePreset();
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
                error: (_, __) => EmptyState.withDefault404(
                  title: loc.mod_preset_load_failed,
                ),
                data: (app) {
                  if (_nameController.text != app.name) {
                    _nameController.text = app.name;
                  }

                  return UTTableFrame<ModView>(
                    controller: _tableCtrl,
                    columns: columns,
                    rows: rows,
                    rowHeight: 52,
                    compactRowHeight: 36,
                    tileRowHeight: 64,
                    rowBaseBackground: (ctx, r) {
                      if (r.isMissing) {
                        final sem = ref.watch(themeSemanticsProvider);
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
                    initialSortColumnId: _colFromSort(app.sortKey ?? ModSortKey.name),
                    initialAscending: app.ascending ?? true,
                    initialDensity: UTTableDensity.tile,
                    comparators: comparators,
                    headerTrailing: UTHeaderRefreshButton(
                      tooltip: loc.common_refresh,
                      onRefresh: () async {
                        await uiCtrl.refreshFromStore();
                        if (!context.mounted) return;
                        UiFeedback.success(
                          context,
                          title: loc.common_refresh,
                          content: loc.mod_table_reloaded,
                        );
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
                            autoModeConfiguration: FlyoutAutoConfiguration(preferredMode: FlyoutPlacementMode.topRight),
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

                        final isTile          = density == UTTableDensity.tile;
                        final isComfortable   = density == UTTableDensity.comfortable;
                        final versionVisible  = vis?.isVisible('version') ?? true;

                        final isNarrowVersion = !versionVisible;
                        const isNarrowPreset  = false; // 프리셋 칼럼 없음

                        final nameForRow = nameOf(r);

                        // InstanceDetailPage와 동일 정책:
                        // 타일 밀도 + version 칼럼 숨김일 때만 제목 아래 버전 한 줄 표시
                        final showVersionUnderTitle = (isTile || isComfortable) && isNarrowVersion;

                        return ModTitleCell(
                          key: ValueKey(r.id),
                          row: r,
                          displayName: nameForRow,
                          showVersionUnderTitle: showVersionUnderTitle,
                          isNarrowVersion: isNarrowVersion,
                          isNarrowPreset:  isNarrowPreset,
                          placeholderFallback: 'M',
                          prewarmPreview: true,
                          onTapTitle: r.modId.isEmpty
                              ? null
                              : () async => ref.read(isaacSteamLinksProvider).openIsaacWorkshopItem(r.modId),
                        );
                      }),
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
                    ],
                    quickFiltersAreAnd: true,
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
