import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/dialogs/game_config_dialog.dart';
import 'package:cartridge/widgets/dialogs/mod_group_dialog.dart';
import 'package:cartridge/widgets/mod_item.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresetEditView extends ConsumerStatefulWidget {
  final Preset selectedPreset;
  final TextEditingController editPresetNameController;
  final TextEditingController searchController;
  final VoidCallback onCancel;
  final Function(List<Mod> mods) onSave;

  const PresetEditView({
    super.key,
    required this.selectedPreset,
    required this.editPresetNameController,
    required this.searchController,
    required this.onCancel,
    required this.onSave,
  });

  @override
  ConsumerState<PresetEditView> createState() => _PresetEditViewState();
}

class _PresetEditViewState extends ConsumerState<PresetEditView> {
  List<Mod> editedMods = [];
  bool _isEditingPresetName = false;
  final Map<String, FlyoutController> _menuControllers = {};

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
    editedMods = ref.read(storeProvider).currentMods.toList();
    for (var mod in editedMods) {
      mod.isDisable = widget.selectedPreset.mods
          .firstWhere(
            (element) => element.name == mod.name,
            orElse: () => Mod(name: "Null", path: "Null", isDisable: true),
          )
          .isDisable;
    }
  }

  void _syncModsWithStore(List<Mod> currentMods) {
    for (var mod in currentMods) {
      mod.isDisable = editedMods
          .firstWhere(
            (element) => element.name == mod.name,
            orElse: () => Mod(name: "Null", path: "Null", isDisable: true),
          )
          .isDisable;
    }
    editedMods = currentMods;
  }

  List<Mod> _getFilteredMods() {
    return editedMods.where((mod) {
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

    // 기존 그룹들을 모두 추가 (빈 그룹도 포함)
    for (final groupName in store.groups.keys) {
      groupedMods[groupName] = [];
    }

    // 미분류 그룹도 추가 (null로 표현)
    groupedMods[null] = [];

    // 모드를 해당 그룹에 할당
    for (final mod in filteredMods) {
      final groupName = store.getModGroup(mod.name);
      groupedMods[groupName]!.add(mod);
    }

    return groupedMods;
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

    ref.listen(storeProvider, (previous, next) {
      _syncModsWithStore(next.currentMods.toList());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPresetNameInput(context),
        _buildControlsRow(context, store, loc),
        _buildModsList(),
        _buildActionButtons(context, loc),
      ],
    );
  }

  Widget _buildPresetNameInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IntrinsicWidth(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 10),
              child: _isEditingPresetName
                  ? TextBox(
                      controller: widget.editPresetNameController,
                      style: FluentTheme.of(context).typography.subtitle,
                      placeholder: '프리셋 이름',
                      onChanged: (value) => widget.selectedPreset.name = value,
                      onSubmitted: (value) {
                        widget.selectedPreset.name = value;
                        setState(() => _isEditingPresetName = false);
                      },
                      autofocus: true,
                    )
                  : GestureDetector(
                      onTap: () => setState(() => _isEditingPresetName = true),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          widget.selectedPreset.name.isEmpty
                              ? '프리셋 이름'
                              : widget.selectedPreset.name,
                          style: widget.selectedPreset.name.isEmpty
                              ? FluentTheme.of(context)
                                  .typography
                                  .subtitle
                                  ?.copyWith(
                                    color: FluentTheme.of(context)
                                        .resources
                                        .textFillColorSecondary,
                                  )
                              : FluentTheme.of(context).typography.subtitle,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_isEditingPresetName
                ? FluentIcons.check_mark
                : FluentIcons.edit),
            onPressed: () {
              if (_isEditingPresetName) {
                widget.selectedPreset.name =
                    widget.editPresetNameController.text;
              } else {
                widget.editPresetNameController.text =
                    widget.selectedPreset.name;
              }
              setState(() => _isEditingPresetName = !_isEditingPresetName);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlsRow(BuildContext context, store, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(top: 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _GameConfigSelector(store: store),
              _buildSearchBox(loc),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(AppLocalizations loc) {
    return SizedBox(
      width: 250,
      child: TextBox(
        controller: widget.searchController,
        placeholder: loc.common_search_placeholder,
        suffix: IgnorePointer(
          child: IconButton(
            onPressed: () {},
            icon: const Icon(FluentIcons.search),
          ),
        ),
      ),
    );
  }

  Widget _buildModsList() {
    return _buildGroupedModsList();
  }

  Widget _buildGroupedModsList() {
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
                groupName ?? '미분류',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                  '(${modsInGroup.where((e) => !e.isDisable).length} / ${modsInGroup.length})',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey,
                  ))
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (groupName != null) ...[
              // 그룹 전체 활성화/비활성화 버튼
              IconButton(
                icon: Icon(
                  _isGroupAllEnabled(groupName, groupedMods) 
                    ? FluentIcons.toggle_left 
                    : FluentIcons.toggle_right,
                  size: 16,
                  color: _isGroupAllEnabled(groupName, groupedMods) 
                    ? Colors.green 
                    : Colors.grey,
                ),
                onPressed: () => _toggleGroupEnabled(groupName, groupedMods),
              ),
              // 더보기 메뉴 버튼
              FlyoutTarget(
                controller: _getMenuController(groupName),
                child: IconButton(
                  icon: const Icon(FluentIcons.more_vertical, size: 16),
                  onPressed: () => _showGroupMenu(context, store, groupName),
                ),
              ),
            ] else
              IconButton(
                icon: const Icon(FluentIcons.add),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => const ModGroupDialog(),
                ),
              ),
          ],
        )
      ],
    );
  }

  FlyoutController _getMenuController(String groupName) {
    if (!_menuControllers.containsKey(groupName)) {
      _menuControllers[groupName] = FlyoutController();
    }
    return _menuControllers[groupName]!;
  }

  void _showGroupMenu(BuildContext context, store, String groupName) {
    _getMenuController(groupName).showFlyout(
      barrierDismissible: true,
      dismissWithEsc: true,
      builder: (context) => MenuFlyout(
        items: [
          MenuFlyoutItem(
            leading: const Icon(FluentIcons.edit),
            text: const Text('이름 변경'),
            onPressed: () {
              Flyout.of(context).close();
              showDialog(
                context: context,
                builder: (context) => ModGroupDialog(
                  initialGroupName: groupName,
                  isEdit: true,
                ),
              );
            },
          ),
          MenuFlyoutItem(
            leading: Icon(FluentIcons.delete, color: Colors.red),
            text: Text('그룹 삭제', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Flyout.of(context).close();
              _showDeleteGroupConfirmDialog(context, store, groupName);
            },
          ),
        ],
      ),
    );
  }

  bool _isGroupAllEnabled(String? groupName, Map<String?, List<Mod>> groupedMods) {
    final mods = groupedMods[groupName] ?? [];
    if (mods.isEmpty) return false;
    return mods.every((mod) => !mod.isDisable);
  }

  void _toggleGroupEnabled(String? groupName, Map<String?, List<Mod>> groupedMods) {
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
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('그룹 삭제'),
        content: Text('$groupName 그룹을 삭제하시겠습니까?'),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              store.removeGroup(groupName);
              Navigator.of(context).pop();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent(String? groupName, List<Mod> mods) {
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
                  ? Colors.blue.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: isHovering ? 1 : 1,
            ),
          ),
          child: mods.isEmpty
              ? Center(
                  child: Text(
                    '모드를 여기로 드래그하세요',
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    const double minTileWidth = 200;
                    const double gap = 16;
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
                                  onChanged: (value) => setState(() {
                                    mod.isDisable = !value;
                                  }),
                                  onMoveToGroup: (targetGroup) {
                                    final store = ref.read(storeProvider);
                                    final currentGroup = store.getModGroup(mod.name);
                                    store.moveModToGroup(mod.name, currentGroup, targetGroup);
                                  },
                                ),
                              ))
                          .toList(),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 4,
          children: [
            Button(
              onPressed: widget.onCancel,
              child: Text(loc.common_cancel),
            ),
            FilledButton(
              onPressed: () => widget.onSave(editedMods),
              child: Text(loc.common_save),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameConfigSelector extends ConsumerWidget {
  final dynamic store;

  const _GameConfigSelector({required this.store});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: ComboBox<String?>(
          placeholder: const Text('게임 설정'),
          value: store.selectedGameConfigId,
          items: _buildComboBoxItems(loc),
          onChanged: (value) => _handleComboBoxChange(context, value),
        ),
      ),
    );
  }

  List<ComboBoxItem<String?>> _buildComboBoxItems(AppLocalizations loc) {
    return [
      ...store.gameConfigs.map((config) => ComboBoxItem<String?>(
            value: config.id,
            child: Text(config.name),
          )),
      ComboBoxItem<String?>(
        value: 'edit',
        child: Row(
          children: [
            const Icon(FluentIcons.edit, size: 14),
            const SizedBox(width: 8),
            Text('편집하기'),
          ],
        ),
      ),
      if (store.selectedGameConfigId != null)
        const ComboBoxItem<String?>(
          value: null,
          child: Row(
            children: [
              const Icon(FluentIcons.clear, size: 14),
              const SizedBox(width: 8),
              Text('선택 해제'),
            ],
          ),
        ),
    ];
  }

  void _handleComboBoxChange(BuildContext context, String? value) {
    if (value == 'edit') {
      showDialog(
        context: context,
        builder: (context) => const GameConfigDialog(),
      );
      return;
    }

    if (value == 'add_new') {
      showDialog(
        context: context,
        builder: (context) => const GameConfigDialog(),
      );
      return;
    }

    if (value == null) {
      store.selectGameConfig(null);
      return;
    }

    store.isSync = false;
    store.selectGameConfig(value);
  }
}
