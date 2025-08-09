import 'package:cartridge/models/option_preset.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class OptionPresetDialog extends ConsumerStatefulWidget {
  const OptionPresetDialog({
    super.key,
    this.id,
  });

  final String? id;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _OptionPresetDialogState();
}

class _OptionPresetDialogState extends ConsumerState<OptionPresetDialog> {
  late OptionPreset _newPreset;
  late TextEditingController _nameController;
  late TextEditingController _windowWidthController;
  late TextEditingController _windowHeightController;
  late TextEditingController _windowPosXController;
  late TextEditingController _windowPosYController;

  @override
  void initState() {
    super.initState();

    _newPreset = ref.read(storeProvider).optionPresets.firstWhere(
          (preset) => preset.id == widget.id,
          orElse: () => OptionPreset(id: widget.id, name: AppLocalizations.of(context).option_preset_fallback_name),
        );

    _nameController = TextEditingController(text: _newPreset.name);
    _windowWidthController =
        TextEditingController(text: _newPreset.windowWidth.toString());
    _windowHeightController =
        TextEditingController(text: _newPreset.windowHeight.toString());
    _windowPosXController =
        TextEditingController(text: _newPreset.windowPosX.toString());
    _windowPosYController =
        TextEditingController(text: _newPreset.windowPosY.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ContentDialog(
      title: Text(loc.option_dialog_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 328,
            child: InfoLabel(
              label: loc.option_name_label,
              child: TextBox(
                controller: _nameController,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            loc.option_window_size_title,
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: loc.option_window_width_label,
                  child: TextBox(
                    controller: _windowWidthController,
                  ),
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: loc.option_window_height_label,
                  child: TextBox(
                    controller: _windowHeightController,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            loc.option_window_position_title,
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: loc.option_window_pos_x_label,
                  child: TextBox(
                    controller: _windowPosXController,
                  ),
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: loc.option_window_pos_y_label,
                  child: TextBox(
                    controller: _windowPosYController,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            ref.read(storeProvider).updateOptionPreset(
                  OptionPreset(
                    id: widget.id,
                    name: _nameController.text,
                    windowWidth: int.parse(_windowWidthController.text),
                    windowHeight: int.parse(_windowHeightController.text),
                    windowPosX: int.parse(_windowPosXController.text),
                    windowPosY: int.parse(_windowPosYController.text),
                  ),
                );

            Navigator.pop(context);
          },
          child: Text(loc.common_save),
        ),
      ],
    );
  }
}
