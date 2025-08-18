import 'package:cartridge/models/preset.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:cartridge/l10n/app_localizations.dart';

class PresetItem extends StatelessWidget {
  const PresetItem({
    super.key,
    required this.preset,
    required this.onApply,
    required this.onDelete,
    required this.onEdit,
    this.isSelected = false,
    this.onTap,
  });

  final Preset preset;

  final Function(Preset preset) onApply;

  final Function(Preset preset) onDelete;

  final Function(Preset preset) onEdit;

  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = FluentTheme.of(context);

    return Card(
      backgroundColor: isSelected
          ? theme.accentColor.withValues(alpha: 0.1)
          : Colors.transparent,
      borderColor: isSelected ? theme.accentColor : Colors.transparent,
      padding: EdgeInsetsGeometry.zero,
      child: material.InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? theme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  preset.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                    color: isSelected ? theme.accentColor : null,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onApply(preset),
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        theme.accentColor.withValues(alpha: 0.1),
                      ),
                    ),
                    icon: Icon(
                      FluentIcons.play,
                      color: theme.accentColor,
                      size: 18,
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
                                backgroundColor: WidgetStatePropertyAll<Color>(
                                    Colors.red.dark),
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
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        Colors.red.withValues(alpha: 0.1),
                      ),
                    ),
                    icon: Icon(
                      FluentIcons.delete,
                      color: Colors.red.dark,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
