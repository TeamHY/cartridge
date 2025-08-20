import 'package:cartridge/models/game_config.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

class GameConfigListView extends StatefulWidget {
  final List<GameConfig> configurations;
  final GameConfig? selectedConfig;
  final ValueChanged<GameConfig?> onConfigSelected;
  final VoidCallback onAddNew;
  final ValueChanged<GameConfig> onDeleteConfig;
  final bool Function(GameConfig) hasUnsavedChanges;

  const GameConfigListView({
    super.key,
    required this.configurations,
    required this.selectedConfig,
    required this.onConfigSelected,
    required this.onAddNew,
    required this.onDeleteConfig,
    required this.hasUnsavedChanges,
  });

  @override
  State<GameConfigListView> createState() => _GameConfigListViewState();
}

class _GameConfigListViewState extends State<GameConfigListView> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: FluentTheme.of(context).resources.subtleFillColorSecondary,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAddButton(loc),
          Expanded(
            child: _buildConfigList(),
          ),
          _buildDeleteButton(loc),
        ],
      ),
    );
  }

  Widget _buildAddButton(AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.only(right: 24),
      child: Button(
        onPressed: widget.onAddNew,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.add, size: 16),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).game_config_add_new),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 16, right: 24),
      itemCount: widget.configurations.length,
      itemBuilder: (context, index) {
        final config = widget.configurations[index];
        final isSelected = widget.selectedConfig?.id == config.id;
        final hasChanges = widget.hasUnsavedChanges(config);
        final theme = FluentTheme.of(context);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Card(
            backgroundColor: isSelected
                ? theme.accentColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderColor: isSelected ? theme.accentColor : Colors.transparent,
            padding: EdgeInsetsGeometry.zero,
            child: material.Material(
              color: Colors.transparent,
              child: material.InkWell(
                onTap: () => widget.onConfigSelected(config),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              config.name.isEmpty
                                  ? AppLocalizations.of(context).common_untitled
                                  : config.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 14,
                                color: isSelected ? theme.accentColor : null,
                                fontStyle: config.name.isEmpty
                                    ? FontStyle.italic
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${config.windowWidth}×${config.windowHeight}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.resources.textFillColorSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasChanges)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppLocalizations.of(context).common_modified,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.dark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(AppLocalizations loc) {
    final canDelete = widget.selectedConfig != null;

    return Container(
      padding: const EdgeInsets.only(right: 24),
      child: Button(
        onPressed: canDelete ? _showDeleteConfirmation : null,
        style: canDelete
            ? ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.red),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.delete, size: 16),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).game_config_delete_selected),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    if (widget.selectedConfig == null) return;

    final loc = AppLocalizations.of(context);
    final configName = widget.selectedConfig!.name;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(AppLocalizations.of(context).game_config_delete_title),
        content: Text(
          loc.game_config_delete_message(configName),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.common_cancel),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll<Color>(Colors.red.dark),
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteConfig(widget.selectedConfig!);
            },
            child: Text(loc.common_delete),
          ),
        ],
      ),
    );
  }
}
