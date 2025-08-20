import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/dialogs/game_config_dialog.dart';
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
        _buildModsList(_getFilteredMods()),
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
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          widget.selectedPreset.name.isEmpty ? '프리셋 이름' : widget.selectedPreset.name,
                          style: widget.selectedPreset.name.isEmpty
                              ? FluentTheme.of(context).typography.subtitle?.copyWith(
                                  color: FluentTheme.of(context).resources.textFillColorSecondary,
                                )
                              : FluentTheme.of(context).typography.subtitle,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(_isEditingPresetName ? FluentIcons.check_mark : FluentIcons.edit),
            onPressed: () {
              if (_isEditingPresetName) {
                widget.selectedPreset.name = widget.editPresetNameController.text;
              } else {
                widget.editPresetNameController.text = widget.selectedPreset.name;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GameConfigSelector(store: store),
          _buildSearchBox(loc),
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

  Widget _buildModsList(List<Mod> filteredMods) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const double minTileWidth = 200;
          const double gap = 16;
          final double width = constraints.maxWidth - gap * 2;
          int columns = (width / (minTileWidth + gap)).floor();
          if (columns < 1) columns = 1;
          final double tileWidth = (width - gap * (columns - 1)) / columns;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: gap),
              child: material.Material(
                color: Colors.transparent,
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: filteredMods
                      .map((mod) => SizedBox(
                            width: tileWidth,
                            child: ModItem(
                              mod: mod,
                              onChanged: (value) => setState(() {
                                mod.isDisable = !value;
                              }),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
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
