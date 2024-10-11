import 'package:cartridge/models/preset.dart';
import 'package:cartridge/widgets/dialogs/preset_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';

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
