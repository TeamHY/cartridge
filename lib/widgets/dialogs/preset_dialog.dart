import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/option_preset_button.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresetDialog extends ConsumerStatefulWidget {
  const PresetDialog({
    super.key,
    required this.preset,
    required this.onEdit,
  });

  final Preset preset;
  final Function(Preset oldPreset, Preset newPreset) onEdit;

  @override
  ConsumerState<PresetDialog> createState() => _PresetDialogState();
}

class _PresetDialogState extends ConsumerState<PresetDialog> {
  bool _isChanged = false;
  late Preset _newPreset;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    final store = ref.read(storeProvider);

    _newPreset = Preset(
      name: widget.preset.name,
      optionPresetId: widget.preset.optionPresetId,
      mods: [],
    );

    store.loadMods().then(
          (value) async => setState(
            () {
              _newPreset.mods = value
                  .map(
                    (mod) => Mod(
                      name: mod.name,
                      path: mod.path,
                      isDisable: widget.preset.mods
                          .firstWhere(
                            (element) => element.name == mod.name,
                            orElse: () => Mod.none,
                          )
                          .isDisable,
                    ),
                  )
                  .toList();

              _newPreset.mods.sort((a, b) {
                if (store.favorites.contains(a.name) &&
                    !store.favorites.contains(b.name)) {
                  return -1;
                } else if (!store.favorites.contains(a.name) &&
                    store.favorites.contains(b.name)) {
                  return 1;
                } else {
                  return a.name.compareTo(b.name);
                }
              });
            },
          ),
        );

    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.read(storeProvider);
    final mods = _newPreset.mods.where(
      (mod) => mod.name.toLowerCase().replaceAll(RegExp('\\s'), "").contains(
            _searchController.text.toLowerCase().replaceAll(RegExp('\\s'), ""),
          ),
    );

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
      title: Text(widget.preset.name),
      content: Column(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ...store.optionPresets.map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OptionPresetButton(
                        id: option.id,
                        checked: option.id == _newPreset.optionPresetId,
                        onChanged: (value) => setState(() {
                          if (!value) {
                            _newPreset.optionPresetId = null;
                            return;
                          }

                          _newPreset.optionPresetId = option.id;
                          _isChanged = true;
                        }),
                        content: option.name,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                width: 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: mods
                      .map(
                        (mod) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: ToggleSwitch(
                            checked: !mod.isDisable,
                            onChanged: (value) {
                              setState(() {
                                mod.isDisable = !value;
                                _isChanged = true;
                              });
                            },
                            content: Text(
                              mod.name,
                              style: TextStyle(
                                color: store.favorites.contains(mod.name)
                                    ? Colors.blue
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
          ),
          TextBox(
            controller: _searchController,
            placeholder: '검색',
            suffix: IgnorePointer(
              child: IconButton(
                onPressed: () {},
                icon: const Icon(FluentIcons.search),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("취소"),
        ),
        FilledButton(
          onPressed: _isChanged
              ? () {
                  widget.onEdit(widget.preset, _newPreset);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("적용"),
        ),
      ],
    );
  }
}
