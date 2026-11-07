import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/game_launch_mode.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/repentogon_provider.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/components/dialogs/game_config_dialog.dart';
import 'package:cartridge/components/dialogs/mod_group_dialog.dart';
import 'package:cartridge/components/save_button.dart';
import 'package:cartridge/pages/home/components/mod_item.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PresetEditView extends ConsumerStatefulWidget {
  final Preset selectedPreset;
  final TextEditingController editPresetNameController;
  final TextEditingController searchController;
  final VoidCallback? onBackPressed;
  final VoidCallback onCancel;
  final Function(String? selectedGameConfigId, GameLaunchMode launchMode,
      List<Mod> mods) onSave;

  const PresetEditView({
    super.key,
    required this.selectedPreset,
    required this.editPresetNameController,
    required this.searchController,
    this.onBackPressed,
    required this.onCancel,
    required this.onSave,
  });

  @override
  ConsumerState<PresetEditView> createState() => _PresetEditViewState();
}

class _PresetEditViewState extends ConsumerState<PresetEditView> {
  String? _selectedGameConfigId;
  GameLaunchMode _launchMode = GameLaunchMode.vanilla;
  List<Mod> _editedMods = [];
  bool _isEditingPresetName = false;

  @override
  void initState() {
    super.initState();
    _resetEditedMods();
  }

  @override
  void didUpdateWidget(covariant PresetEditView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetEditedMods();
    _isEditingPresetName = false;
  }

  void _resetEditedMods() {
    _selectedGameConfigId = widget.selectedPreset.gameConfigId;
    _launchMode = widget.selectedPreset.launchMode;
    _editedMods = ref.read(storeProvider).currentMods.toList();
    for (var mod in _editedMods) {
      mod.isDisable = widget.selectedPreset.mods
          .firstWhere(
            (element) => element.name == mod.name,
            orElse: () => Mod(name: "Null", path: "Null", isDisable: true),
          )
          .isDisable;
    }
  }

  List<Mod> _getFilteredMods() {
    return _editedMods.where((mod) {
      final searchText = widget.searchController.text
          .toLowerCase()
          .replaceAll(RegExp('\\s'), "");
      final modName = mod.name.toLowerCase().replaceAll(RegExp('\\s'), "");
      return modName.contains(searchText);
    }).toList();
  }

  Map<String?, List<Mod>> _getModsByGroup() {
    final store = ref.read(storeProvider);
    final filteredMods = _getFilteredMods();
    final Map<String?, List<Mod>> groupedMods = {};

    for (final groupName in store.groups.keys) {
      groupedMods[groupName] = [];
    }

    groupedMods[null] = [];

    for (final mod in filteredMods) {
      final groupName = store.getModGroup(mod.name);
      groupedMods[groupName]!.add(mod);
    }

    return groupedMods;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(loc),
        _buildModsList(),
        _buildActionButtons(context, loc),
      ],
    );
  }

  void _toggleRename() {
    if (_isEditingPresetName) {
      widget.selectedPreset.name = widget.editPresetNameController.text;
    } else {
      widget.editPresetNameController.text = widget.selectedPreset.name;
    }
    setState(() => _isEditingPresetName = !_isEditingPresetName);
  }

  Widget _buildHeader(AppLocalizations loc) {
    final c = AppColors.of(context);
    final setting = ref.watch(settingProvider);

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 8,
        children: [
          if (widget.onBackPressed != null)
            AppIconButton(
              icon: const PhosphorIcon(PhosphorIconsRegular.arrowLeft),
              onPressed: widget.onBackPressed,
            ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _isEditingPresetName
                  ? SizedBox(
                      width: 280,
                      child: AppTextField(
                        controller: widget.editPresetNameController,
                        placeholder: loc.preset_edit_name_placeholder,
                        autofocus: true,
                        onChanged: (value) => setState(() {
                          widget.selectedPreset.name = value;
                        }),
                        onSubmitted: (value) {
                          widget.selectedPreset.name = value;
                          setState(() => _isEditingPresetName = false);
                        },
                        suffix: AppIconButton(
                          icon: const PhosphorIcon(PhosphorIconsBold.check),
                          size: 24,
                          onPressed: _toggleRename,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 2,
                      children: [
                        Flexible(
                          child: Text(
                            widget.selectedPreset.name.isEmpty
                                ? loc.preset_edit_name_placeholder
                                : widget.selectedPreset.name,
                            style: AppTextStyles.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppIconButton(
                          icon: const PhosphorIcon(
                              PhosphorIconsRegular.pencilSimple),
                          onPressed: _toggleRename,
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(
            width: 220,
            child: AppTextField(
              controller: widget.searchController,
              placeholder: loc.common_search_placeholder,
              prefix: const PhosphorIcon(
                PhosphorIconsRegular.magnifyingGlass,
                size: 16,
              ),
            ),
          ),
          AppSegmented<bool>(
            value: setting.isGridView,
            segments: [
              AppSegment(
                value: false,
                label: loc.preset_edit_view_list,
                icon: const PhosphorIcon(PhosphorIconsRegular.rows),
              ),
              AppSegment(
                value: true,
                label: loc.preset_edit_view_grid,
                icon: const PhosphorIcon(PhosphorIconsRegular.gridFour),
              ),
            ],
            onChanged: (value) {
              setting.isGridView = value;
              setting.saveSetting();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModsList() {
    final groupedMods = _getModsByGroup();
    final store = ref.read(storeProvider);

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: groupedMods.entries.map((entry) {
              final groupName = entry.key;
              final mods = entry.value;

              return _buildGroupSection(groupName, mods, store);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(String? groupName, List<Mod> mods, store) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGroupHeader(groupName, store),
          const SizedBox(height: 12),
          _buildGroupContent(groupName, mods),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String? groupName, store) {
    final loc = AppLocalizations.of(context);
    final groupedMods = _getModsByGroup();
    final modsInGroup = groupedMods[groupName] ?? [];

    return Row(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.ideographic,
            spacing: 4,
            children: [
              Text(
                groupName ?? loc.group_uncategorized,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                  '(${modsInGroup.where((e) => !e.isDisable).length} / ${modsInGroup.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: AppColors.of(context).ink3,
                  ))
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (groupName != null) ...[
              AppIconButton(
                active: _isGroupAllEnabled(groupName, groupedMods),
                icon: PhosphorIcon(
                  _isGroupAllEnabled(groupName, groupedMods)
                      ? PhosphorIconsFill.toggleRight
                      : PhosphorIconsFill.toggleLeft,
                  size: 16,
                ),
                onPressed: () => _toggleGroupEnabled(groupName, groupedMods),
              ),
              _buildGroupMenu(store, groupName),
            ] else
              AppButton.ghost(
                onPressed: () => showAppDialog(
                  context: context,
                  builder: (context) => const ModGroupDialog(),
                ),
                child: const Row(
                  children: [
                    PhosphorIcon(PhosphorIconsRegular.plus),
                    SizedBox(width: 4),
                    Text("그룹 생성"),
                  ],
                ),
              ),
          ],
        )
      ],
    );
  }

  Widget _buildGroupMenu(store, String groupName) {
    final loc = AppLocalizations.of(context);
    final danger = AppColors.of(context).danger;

    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple),
          onPressed: () => showAppDialog(
            context: context,
            builder: (context) => ModGroupDialog(
              initialGroupName: groupName,
              isEdit: true,
            ),
          ),
          child: Text(loc.group_rename),
        ),
        MenuItemButton(
          leadingIcon: const PhosphorIcon(PhosphorIconsRegular.trash),
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(danger),
            iconColor: WidgetStatePropertyAll(danger),
          ),
          onPressed: () =>
              _showDeleteGroupConfirmDialog(context, store, groupName),
          child: Text(loc.group_delete),
        ),
      ],
      builder: (context, controller, _) => AppIconButton(
        icon: const PhosphorIcon(PhosphorIconsBold.dotsThreeVertical, size: 16),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  bool _isGroupAllEnabled(
      String? groupName, Map<String?, List<Mod>> groupedMods) {
    final mods = groupedMods[groupName] ?? [];
    if (mods.isEmpty) return false;
    return mods.every((mod) => !mod.isDisable);
  }

  void _toggleGroupEnabled(
      String? groupName, Map<String?, List<Mod>> groupedMods) {
    final mods = groupedMods[groupName] ?? [];
    if (mods.isEmpty) return;

    final shouldEnable = !_isGroupAllEnabled(groupName, groupedMods);

    setState(() {
      for (final mod in mods) {
        mod.isDisable = !shouldEnable;
      }
    });
  }

  void _showDeleteGroupConfirmDialog(
      BuildContext context, store, String groupName) {
    showAppDialog(
      context: context,
      builder: (context) => AppDialog(
        constraints: const BoxConstraints(maxWidth: 368),
        title: Text(AppLocalizations.of(context).group_delete),
        content:
            Text(AppLocalizations.of(context).group_delete_confirm(groupName)),
        actions: [
          AppButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).common_cancel),
          ),
          AppButton.danger(
            onPressed: () {
              store.removeGroup(groupName);
              Navigator.of(context).pop();
            },
            child: Text(AppLocalizations.of(context).common_delete),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent(String? groupName, List<Mod> mods) {
    final setting = ref.watch(settingProvider);

    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final modName = details.data;
        final store = ref.read(storeProvider);
        final currentGroup = store.getModGroup(modName);

        if (currentGroup == groupName) return;

        if (groupName == null) {
          if (currentGroup != null) {
            store.removeModFromGroup(currentGroup, modName);
          }
        } else {
          store.moveModToGroup(modName, currentGroup, groupName);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 60),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHovering
                  ? AppColors.of(context).enabledLine
                  : Colors.transparent,
              width: isHovering ? 1 : 1,
            ),
          ),
          child: mods.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).mod_drag_here,
                    style: TextStyle(
                      color: AppColors.of(context).ink3,
                    ),
                  ),
                )
              : setting.isGridView
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        const double minTileWidth = 200;
                        const double gap = 8;
                        final double width = constraints.maxWidth;
                        int columns = (width / (minTileWidth + gap)).floor();
                        if (columns < 1) columns = 1;
                        final double tileWidth =
                            (width - gap * (columns - 1)) / columns;

                        return Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          children: mods
                              .map((mod) => SizedBox(
                                    width: tileWidth,
                                    child: ModItem(
                                      mod: mod,
                                      isDraggable: true,
                                      isGridItem: true,
                                      onChanged: (value) => setState(() {
                                        mod.isDisable = !value;
                                      }),
                                      onMoveToGroup: (targetGroup) {
                                        final store = ref.read(storeProvider);
                                        final currentGroup =
                                            store.getModGroup(mod.name);
                                        store.moveModToGroup(mod.name,
                                            currentGroup, targetGroup);
                                      },
                                    ),
                                  ))
                              .toList(),
                        );
                      },
                    )
                  : Column(
                      spacing: 8,
                      children: mods
                          .map((mod) => SizedBox(
                                width: double.infinity,
                                child: ModItem(
                                  mod: mod,
                                  isDraggable: true,
                                  onChanged: (value) => setState(() {
                                    mod.isDisable = !value;
                                  }),
                                  onMoveToGroup: (targetGroup) {
                                    final store = ref.read(storeProvider);
                                    final currentGroup =
                                        store.getModGroup(mod.name);
                                    store.moveModToGroup(
                                        mod.name, currentGroup, targetGroup);
                                  },
                                ),
                              ))
                          .toList(),
                    ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.surface1,
        boxShadow: [
          BoxShadow(
            color: c.line,
            blurRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 4,
          children: [
            if (RepentogonNotifier.isSupported) ...[
              Text(loc.setting_launch_mode_label),
              const SizedBox(width: 4),
              for (final mode in GameLaunchMode.values)
                AppToggleButton(
                  checked: _launchMode == mode,
                  onChanged: (_) => setState(() => _launchMode = mode),
                  child: Text(mode == GameLaunchMode.repentogon
                      ? loc.setting_launch_mode_repentogon
                      : loc.setting_launch_mode_vanilla),
                ),
              const SizedBox(width: 20),
            ],
            Text(loc.preset_edit_game_window_label),
            const SizedBox(width: 4),
            _GameConfigSelector(
              selectedGameConfigId: _selectedGameConfigId,
              selectGameConfig: (value) =>
                  setState(() => _selectedGameConfigId = value),
            ),
            AppIconButton(
              tooltip: loc.game_config_edit,
              icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple),
              onPressed: () => showAppDialog(
                context: context,
                builder: (context) => const GameConfigDialog(),
              ),
            ),
            const Spacer(),
            AppButton(
              onPressed: widget.onCancel,
              child: Text(loc.common_cancel),
            ),
            SaveButton(
              onPressed: () {
                final mods = <Mod>[];

                for (var mod in _editedMods) {
                  if (!mod.isDisable) {
                    mods.add(Mod.fromJson(mod.toJson()));
                  }
                }

                widget.onSave(_selectedGameConfigId, _launchMode, mods);
              },
              child: Text(loc.common_save),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameConfigSelector extends ConsumerWidget {
  final String? selectedGameConfigId;
  final ValueChanged<String?> selectGameConfig;

  const _GameConfigSelector({
    required this.selectedGameConfigId,
    required this.selectGameConfig,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final configs = ref.watch(storeProvider).gameConfigs;
    final hasSelected =
        configs.any((config) => config.id == selectedGameConfigId);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: AppSelect<String?>(
        isExpanded: true,
        placeholder: Text(loc.preset_edit_game_window_none),
        value: hasSelected ? selectedGameConfigId : null,
        items: [
          AppSelectItem<String?>(
            value: null,
            child: Text(loc.preset_edit_game_window_none),
          ),
          ...configs.map((config) => AppSelectItem<String?>(
                value: config.id,
                child: Text(config.name, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: selectGameConfig,
      ),
    );
  }
}
