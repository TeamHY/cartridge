import 'package:cartridge/models/mod.dart';
import 'package:cartridge/models/preset.dart';
import 'package:cartridge/providers/setting_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PresetItem extends StatelessWidget {
  const PresetItem({
    super.key,
    required this.preset,
    required this.onApply,
    required this.onDelete,
    required this.onEdit,
  });

  final Preset preset;

  final Function(Preset preset) onApply;

  final Function(Preset preset) onDelete;

  final Function(Preset oldPreset, Preset newPreset) onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(child: Text(preset.name)),
          IconButton(
            onPressed: () => onApply(preset),
            icon: const Icon(
              FluentIcons.play,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) {
                return PresetDialog(
                  preset: preset,
                  onEdit: onEdit,
                );
              },
            ),
            icon: const Icon(
              FluentIcons.edit,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) {
                return ContentDialog(
                  title: const Text("프리셋 삭제"),
                  content: const Text('프리셋을 삭제하면 복구할 수 없습니다. 정말 삭제하시겠습니까?'),
                  actions: [
                    Button(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            ButtonState.all<Color>(Colors.red.dark),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(preset);
                      },
                      child: const Text('삭제'),
                    ),
                  ],
                );
              },
            ),
            icon: Icon(
              FluentIcons.delete,
              color: Colors.red.dark,
            ),
          )
        ],
      ),
    );
  }
}

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
  bool isChanged = false;
  late Preset newPreset;

  @override
  void initState() {
    super.initState();

    final store = ref.read(storeProvider);

    newPreset = Preset(name: widget.preset.name, mods: []);

    store.loadMods().then(
          (value) async => setState(
            () {
              newPreset.mods = value
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

              newPreset.mods.sort((a, b) {
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
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.read(storeProvider);

    return ContentDialog(
      title: Text(widget.preset.name),
      content: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: newPreset.mods
                    .map(
                      (mod) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: ToggleSwitch(
                          checked: !mod.isDisable,
                          onChanged: (value) {
                            setState(() {
                              mod.isDisable = !value;
                              isChanged = true;
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
          onPressed: isChanged
              ? () {
                  widget.onEdit(widget.preset, newPreset);
                  Navigator.pop(context);
                }
              : null,
          child: const Text("적용"),
        ),
      ],
    );
  }
}
