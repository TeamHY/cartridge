import 'dart:io';
import 'package:cartridge/constants/urls.dart';
import 'package:cartridge/models/mod.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ModItem extends ConsumerStatefulWidget {
  const ModItem({
    super.key,
    required this.mod,
    required this.onChanged,
    this.isDraggable = false,
    this.isGridItem = false,
    this.onMoveToGroup,
  });

  final Mod mod;
  final Function(bool value) onChanged;
  final bool isDraggable;
  final bool isGridItem;
  final Function(String? groupName)? onMoveToGroup;

  @override
  ConsumerState<ModItem> createState() => _ModItemState();
}

class _ModItemState extends ConsumerState<ModItem> {
  final MenuController _menuController = MenuController();

  void _openModFolder() async {
    try {
      if (Platform.isWindows) {
        await Process.run(
            'explorer', [widget.mod.path.replaceAll(RegExp('/'), "\\")]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [widget.mod.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [widget.mod.path]);
      }
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  void _openModWorkshop() async {
    await launchUrl(
        Uri.parse('${AppUrls.steamWorkshopDetail}/?id=${widget.mod.id}'));
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    final store = ref.read(storeProvider);
    final currentGroup = store.getModGroup(widget.mod.name);
    final loc = AppLocalizations.of(context);

    return [
      MenuItemButton(
        leadingIcon: const PhosphorIcon(PhosphorIconsRegular.folderOpen),
        onPressed: _openModFolder,
        child: Text(loc.mod_open_folder),
      ),
      if (widget.mod.id != null) ...[
        MenuItemButton(
          leadingIcon: const PhosphorIcon(PhosphorIconsRegular.link),
          onPressed: _openModWorkshop,
          child: Text(loc.mod_open_workshop),
        ),
      ],
      if (widget.onMoveToGroup != null) ...[
        const Divider(),
        SubmenuButton(
          leadingIcon:
              const PhosphorIcon(PhosphorIconsRegular.arrowsOutCardinal),
          menuChildren: [
            ...store.groups.keys.where((group) => group != currentGroup).map(
                  (groupName) => MenuItemButton(
                    onPressed: () => widget.onMoveToGroup!(groupName),
                    child: Text(groupName),
                  ),
                ),
            if (currentGroup != null)
              MenuItemButton(
                style: ButtonStyle(
                  foregroundColor:
                      WidgetStatePropertyAll(AppColors.of(context).danger),
                ),
                onPressed: () => widget.onMoveToGroup!(null),
                child: Text(loc.mod_remove_from_group),
              ),
          ],
          child: Text(loc.mod_move_to_group),
        ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.mod.isDisable;
    final c = AppColors.of(context);

    Widget child = MenuAnchor(
      controller: _menuController,
      menuChildren: _buildMenuItems(context),
      child: Tooltip(
        message: widget.mod.name,
        child: AppPressable(
          onPressed: () => widget.onChanged(widget.mod.isDisable),
          onSecondaryTapUp: (details) =>
              _menuController.open(position: details.localPosition),
          focusRadius: 12,
          builder: (context, states) {
            final hovered = states.contains(WidgetState.hovered);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: enabled
                    ? c.enabledSoft
                    : (hovered ? c.surface3 : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: enabled
                      ? (hovered ? c.enabled : c.enabledLine)
                      : (hovered ? c.lineStrong : c.line),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 12,
                children: [
                  Expanded(
                    child: Flex(
                      direction:
                          widget.isGridItem ? Axis.vertical : Axis.horizontal,
                      crossAxisAlignment: widget.isGridItem
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisSize: MainAxisSize.min,
                      spacing: widget.isGridItem ? 0 : 4,
                      children: [
                        Text(
                          widget.mod.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: enabled ? c.enabledInk : c.ink2,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.mod.version != null &&
                                    widget.mod.version!.trim().isNotEmpty
                                ? 'v${widget.mod.version}'
                                : AppLocalizations.of(context)
                                    .mod_version_unknown,
                            style: TextStyle(
                              fontSize: 12,
                              color: enabled ? c.enabled : c.ink3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PhosphorIcon(
                    enabled
                        ? PhosphorIconsFill.checkCircle
                        : PhosphorIconsRegular.circle,
                    size: 20,
                    color: enabled ? c.enabled : c.lineStrong,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (widget.isDraggable) {
      return LayoutBuilder(
        builder: (context, constraints) => Draggable<String>(
          data: widget.mod.name,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: enabled ? c.enabledSoft : c.surface3,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: c.shadowMenu,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: constraints,
              child: Text(
                widget.mod.name,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: enabled ? c.enabledInk : c.ink2,
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
        ),
      );
    }

    return child;
  }
}
