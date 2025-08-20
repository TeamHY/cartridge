import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/dialogs/game_config_dialog.dart';
import 'package:cartridge/widgets/mod_item.dart';
import 'package:cartridge/widgets/game_config_button.dart';
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

  @override
  void initState() {
    super.initState();

    _resetEditedMods();
  }

  @override
  void didUpdateWidget(covariant PresetEditView oldWidget) {
    super.didUpdateWidget(oldWidget);

    _resetEditedMods();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProvider);
    final loc = AppLocalizations.of(context);

    ref.listen(storeProvider, (previous, next) {
      final currentMods = next.currentMods.toList();

      for (var mod in currentMods) {
        mod.isDisable = editedMods
            .firstWhere(
              (element) => element.name == mod.name,
              orElse: () => Mod(name: "Null", path: "Null", isDisable: true),
            )
            .isDisable;
      }

      editedMods = currentMods;
    });

    final filteredMods = editedMods.where(
      (mod) => mod.name.toLowerCase().replaceAll(RegExp('\\s'), "").contains(
            widget.searchController.text
                .toLowerCase()
                .replaceAll(RegExp('\\s'), ""),
          ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextBox(
            controller: widget.editPresetNameController,
            style: FluentTheme.of(context).typography.subtitle,
            placeholder: '프리셋 이름',
            onChanged: (value) {
              widget.selectedPreset.name = value;
            },
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ...store.gameConfigs.map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GameConfigButton(
                      id: option.id,
                      checked: option.id == store.selectedGameConfigId,
                      onChanged: (value) {
                        if (!value) {
                          store.selectGameConfig(
                            null,
                          );
                          return;
                        }

                        store.isSync = false;
                        store.selectGameConfig(
                          option.id,
                        );
                      },
                      onEdited: (id) => showDialog(
                        context: context,
                        builder: (context) => GameConfigDialog(
                          id: id,
                        ),
                      ),
                      onDeleted: (id) => showDialog(
                        context: context,
                        builder: (context) {
                          return ContentDialog(
                            title: Text(loc.home_dialog_delete_title),
                            content: Text(loc.home_dialog_delete_description),
                            actions: [
                              Button(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(loc.common_cancel),
                              ),
                              FilledButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStatePropertyAll<Color>(
                                          Colors.red.dark),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  store.removeGameConfig(id);
                                },
                                child: Text(loc.common_delete),
                              ),
                            ],
                          );
                        },
                      ),
                      content: option.name,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(FluentIcons.add),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (context) => const GameConfigDialog(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
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
                          .map(
                            (mod) => SizedBox(
                              width: tileWidth,
                              child: ModItem(
                                mod: mod,
                                onChanged: (value) => setState(() {
                                  mod.isDisable = !value;
                                }),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
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
        ),
        Container(
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
        )
      ],
    );
  }
}
