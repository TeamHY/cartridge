import 'package:cartridge/models/preset.dart';
import 'package:cartridge/widgets/dialogs/preset_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:cartridge/l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);

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
                  title: Text(loc.preset_delete_title),
                  content: Text(loc.preset_delete_message),
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
                            ButtonState.all<Color>(Colors.red.dark),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete(preset);
                      },
                      child: Text(loc.common_delete),
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
