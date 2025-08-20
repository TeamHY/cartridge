import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class GameConfigDialog extends ConsumerStatefulWidget {
  const GameConfigDialog({
    super.key,
    this.id,
  });

  final String? id;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GameConfigDialogState();
}

class _GameConfigDialogState extends ConsumerState<GameConfigDialog> {
  late GameConfig _newConfig;
  late TextEditingController _nameController;
  late TextEditingController _windowWidthController;
  late TextEditingController _windowHeightController;
  late TextEditingController _windowPosXController;
  late TextEditingController _windowPosYController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (!_initialized) {
      _newConfig = ref.read(storeProvider).gameConfigs.firstWhere(
            (config) => config.id == widget.id,
            orElse: () => GameConfig(id: widget.id, name: AppLocalizations.of(context).game_config_fallback_name),
          );

      _nameController = TextEditingController(text: _newConfig.name);
      _windowWidthController =
          TextEditingController(text: _newConfig.windowWidth.toString());
      _windowHeightController =
          TextEditingController(text: _newConfig.windowHeight.toString());
      _windowPosXController =
          TextEditingController(text: _newConfig.windowPosX.toString());
      _windowPosYController =
          TextEditingController(text: _newConfig.windowPosY.toString());
      
      _initialized = true;
    }
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
      title: Text(loc.game_config_dialog_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 328,
            child: InfoLabel(
              label: loc.game_config_name_label,
              child: TextBox(
                controller: _nameController,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            loc.game_config_window_size_title,
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: loc.game_config_window_width_label,
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
                  label: loc.game_config_window_height_label,
                  child: TextBox(
                    controller: _windowHeightController,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            loc.game_config_window_position_title,
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InfoLabel(
                  label: loc.game_config_window_pos_x_label,
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
                  label: loc.game_config_window_pos_y_label,
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
            ref.read(storeProvider).updateGameConfig(
                  GameConfig(
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