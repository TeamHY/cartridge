import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/components/game_config_list_view.dart';
import 'package:cartridge/components/game_config_form_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class GameConfigDialog extends ConsumerStatefulWidget {
  const GameConfigDialog({
    super.key,
  });

  @override
  ConsumerState<GameConfigDialog> createState() => _GameConfigDialogState();
}

class _GameConfigDialogState extends ConsumerState<GameConfigDialog> {
  List<GameConfig> _configurations = [];
  GameConfig? _selectedConfig;
  final Map<String, GameConfig> _originalConfigs = {};
  final Map<String, GameConfig> _editedConfigs = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfigurations();
  }

  void _loadConfigurations() {
    final store = ref.read(storeProvider);
    _configurations = List.from(store.gameConfigs);

    for (final config in _configurations) {
      _originalConfigs[config.id] = config;
      _editedConfigs[config.id] = config;
    }

    if (_configurations.isNotEmpty) {
      _selectedConfig = _configurations.first;
    }
  }

  bool _hasUnsavedChanges(GameConfig config) {
    final original = _originalConfigs[config.id];
    final edited = _editedConfigs[config.id];

    if (original == null || edited == null) return false;

    return original.name != edited.name ||
        original.windowWidth != edited.windowWidth ||
        original.windowHeight != edited.windowHeight ||
        original.windowPosX != edited.windowPosX ||
        original.windowPosY != edited.windowPosY;
  }

  bool get _hasAnyUnsavedChanges {
    return _editedConfigs.values.any(_hasUnsavedChanges);
  }

  void _onConfigSelected(GameConfig? config) {
    setState(() {
      _selectedConfig = config;
    });
  }

  void _onConfigChanged(GameConfig updatedConfig) {
    setState(() {
      _editedConfigs[updatedConfig.id] = updatedConfig;

      final index = _configurations.indexWhere((c) => c.id == updatedConfig.id);
      if (index != -1) {
        _configurations[index] = updatedConfig;
      }
    });
  }

  void _onAddNew() {
    final loc = AppLocalizations.of(context);
    final newConfig = GameConfig(
      name: loc.game_config_fallback_name,
    );

    setState(() {
      _configurations.add(newConfig);
      _originalConfigs[newConfig.id] = newConfig;
      _editedConfigs[newConfig.id] = newConfig;
      _selectedConfig = newConfig;
    });
  }

  void _onDeleteConfig(GameConfig config) {
    setState(() {
      _configurations.removeWhere((c) => c.id == config.id);
      _originalConfigs.remove(config.id);
      _editedConfigs.remove(config.id);

      if (_selectedConfig?.id == config.id) {
        _selectedConfig =
            _configurations.isNotEmpty ? _configurations.first : null;
      }
    });
  }

  void _onSaveConfig() {
    if (_selectedConfig == null) return;

    final edited = _editedConfigs[_selectedConfig!.id];
    if (edited == null) return;

    setState(() {
      _originalConfigs[edited.id] = edited;
    });

    _saveAllChanges();
  }

  void _onResetConfig() {
    if (_selectedConfig == null) return;

    final original = _originalConfigs[_selectedConfig!.id];
    if (original == null) return;

    setState(() {
      _editedConfigs[original.id] = original;

      final index = _configurations.indexWhere((c) => c.id == original.id);
      if (index != -1) {
        _configurations[index] = original;
        _selectedConfig = original;
      }
    });
  }

  void _showUnsavedChangesDialog(VoidCallback onContinue) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(
            AppLocalizations.of(context).game_config_unsaved_changes_title),
        content: Text(
            AppLocalizations.of(context).game_config_unsaved_changes_message),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).game_config_back),
          ),
          Button(
            onPressed: () {
              Navigator.pop(context);
              _onResetConfig();
              onContinue();
            },
            child: Text(AppLocalizations.of(context).game_config_discard),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _onSaveConfig();
              onContinue();
            },
            child: Text(AppLocalizations.of(context).game_config_save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAllChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final store = ref.read(storeProvider);

      for (final config in store.gameConfigs) {
        if (!_configurations.any((c) => c.id == config.id)) {
          store.removeGameConfig(config.id);
        }
      }

      for (final config in _editedConfigs.values) {
        store.updateGameConfig(config);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onCancel() {
    if (_hasAnyUnsavedChanges) {
      _showUnsavedChangesDialog(() {
        Navigator.pop(context);
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ContentDialog(
      constraints: const BoxConstraints(
        maxWidth: 800,
        maxHeight: 600,
      ),
      title: Text(AppLocalizations.of(context).game_config_management_title),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameConfigListView(
            configurations: _configurations,
            selectedConfig: _selectedConfig,
            onConfigSelected: _onConfigSelected,
            onAddNew: _onAddNew,
            onDeleteConfig: _onDeleteConfig,
            hasUnsavedChanges: _hasUnsavedChanges,
          ),
          Expanded(
            child: GameConfigFormView(
              config: _selectedConfig,
              onConfigChanged: _onConfigChanged,
              hasUnsavedChanges: () =>
                  _selectedConfig != null &&
                  _hasUnsavedChanges(_selectedConfig!),
              onSave: _onSaveConfig,
              onReset: _onResetConfig,
            ),
          ),
        ],
      ),
    );
  }
}
