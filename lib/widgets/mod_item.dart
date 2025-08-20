import 'dart:io';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class ModItem extends ConsumerStatefulWidget {
  const ModItem({
    super.key,
    required this.mod,
    required this.onChanged,
    this.isDraggable = false,
    this.onMoveToGroup,
  });

  final Mod mod;
  final Function(bool value) onChanged;
  final bool isDraggable;
  final Function(String? groupName)? onMoveToGroup;

  @override
  ConsumerState<ModItem> createState() => _ModItemState();
}

class _ModItemState extends ConsumerState<ModItem> {
  final fluent.FlyoutController _flyoutController = fluent.FlyoutController();

  void _openModFolder() async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [widget.mod.path]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [widget.mod.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [widget.mod.path]);
      }
    } catch (e) {
      // Error handling
    }
  }

  void _showContextMenu() {
    final store = ref.read(storeProvider);
    final currentGroup = store.getModGroup(widget.mod.name);

    _flyoutController.showFlyout(
      barrierDismissible: true,
      dismissWithEsc: true,
      builder: (context) => fluent.MenuFlyout(
        items: [
          fluent.MenuFlyoutItem(
            leading: const Icon(fluent.FluentIcons.folder_open),
            text: Text(AppLocalizations.of(context).mod_open_folder),
            onPressed: () {
              fluent.Flyout.of(context).close();
              _openModFolder();
            },
          ),
          if (widget.onMoveToGroup != null) ...[
            const fluent.MenuFlyoutSeparator(),
            fluent.MenuFlyoutSubItem(
              leading: const Icon(fluent.FluentIcons.move),
              text: Text(AppLocalizations.of(context).mod_move_to_group),
              items: (context) => [
                ...store.groups.keys
                    .where((group) => group != currentGroup)
                    .map(
                      (groupName) => fluent.MenuFlyoutItem(
                        text: Text(groupName),
                        onPressed: () {
                          fluent.Flyout.of(context).close();
                          widget.onMoveToGroup!(groupName);
                        },
                      ),
                    ),
                if (currentGroup != null)
                  fluent.MenuFlyoutItem(
                    text: Text(
                      AppLocalizations.of(context).mod_remove_from_group,
                      style: TextStyle(color: fluent.Colors.red),
                    ),
                    onPressed: () {
                      fluent.Flyout.of(context).close();
                      widget.onMoveToGroup!(null);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.mod.isDisable;

    Widget child = fluent.FlyoutTarget(
      controller: _flyoutController,
      child: fluent.Tooltip(
        message: widget.mod.name,
        useMousePosition: false,
        child: GestureDetector(
          onSecondaryTap: () => _showContextMenu(),
          child: InkWell(
            onTap: () => widget.onChanged(widget.mod.isDisable),
            borderRadius: BorderRadius.circular(12),
            splashColor: enabled
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            highlightColor: enabled
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: enabled
                    ? Colors.green.withValues(alpha: 0.08)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.mod.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color:
                                enabled ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.mod.version != null &&
                                    widget.mod.version!.trim().isNotEmpty
                                ? 'v${widget.mod.version}'
                                : AppLocalizations.of(context).mod_version_unknown,
                            style: TextStyle(
                              fontSize: 12,
                              color: enabled
                                  ? Colors.green[600]
                                  : Colors.grey[500],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    enabled ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: enabled ? Colors.green[600] : Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.isDraggable) {
      return Draggable<String>(
        data: widget.mod.name,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.green.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.mod.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: enabled ? Colors.green[700] : Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.5,
          child: child,
        ),
        child: child,
      );
    }

    return child;
  }
}
