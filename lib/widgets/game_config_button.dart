import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:cartridge/l10n/app_localizations.dart';

class GameConfigButton extends StatefulWidget {
  const GameConfigButton({
    super.key,
    this.id,
    required this.checked,
    required this.onChanged,
    this.onEdited,
    this.onDeleted,
    required this.content,
  });

  final String? id;
  final bool checked;
  final Function(bool value) onChanged;
  final Function(String id)? onEdited;
  final Function(String id)? onDeleted;
  final String content;

  @override
  State<GameConfigButton> createState() => GameConfigButtonState();
}

class GameConfigButtonState extends State<GameConfigButton> {
  final _menuController = FlyoutController();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return FlyoutTarget(
      controller: _menuController,
      child: material.Material(
        shape: material.RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: widget.checked ? Colors.blue : Colors.grey[50],
            width: widget.checked ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        child: material.InkWell(
          onTap: () => widget.onChanged(!widget.checked),
          onSecondaryTap: () {
            if (widget.onEdited == null || widget.onDeleted == null) return;

            _menuController.showFlyout(
              autoModeConfiguration: FlyoutAutoConfiguration(
                preferredMode: FlyoutPlacementMode.bottomCenter,
              ),
              barrierDismissible: true,
              dismissWithEsc: true,
              builder: (context) {
                return MenuFlyout(items: [
                  MenuFlyoutItem(
                    leading: const Icon(FluentIcons.edit),
                    text: Text(loc.common_edit),
                    onPressed: () {
                      Flyout.of(context).close();
                      widget.onEdited!(widget.id!);
                    },
                  ),
                  MenuFlyoutItem(
                    leading: Icon(
                      FluentIcons.delete,
                      color: Colors.red,
                    ),
                    text: Text(loc.common_delete),
                    onPressed: () {
                      Flyout.of(context).close();
                      widget.onDeleted!(widget.id!);
                    },
                  ),
                ]);
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.content,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}