import 'dart:io';

import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/components/dialogs/setting_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class Layout extends ConsumerWidget {
  const Layout({super.key, required this.child, required this.onHomePressed});

  final Widget child;

  final VoidCallback onHomePressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final musicPlayer = ref.watch(musicPlayerProvider);

    void onRefresh() {
      store.reloadMods();
      musicPlayer.reloadPlaylist();
    }

    Widget buildWindowsTitleBar(BuildContext context, WidgetRef ref) {
      return NavigationView(
        appBar: NavigationAppBar(
          height: 32,
          automaticallyImplyLeading: false,
          title: const DragToMoveArea(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Cartridge'),
            ]),
          ),
          actions: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsRegular.house,
                        size: 16),
                    onPressed: onHomePressed,
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    icon: const PhosphorIcon(
                        PhosphorIconsRegular.arrowClockwise,
                        size: 16),
                    onPressed: onRefresh,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsRegular.gearSix,
                        size: 16),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const SettingDialog(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 138,
                    height: 50,
                    child: WindowCaption(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        content: material.Material(
          color: Colors.transparent,
          child: child,
        ),
      );
    }

    Widget buildMacOSTitleBar(BuildContext context, WidgetRef ref) {
      return NavigationView(
        appBar: NavigationAppBar(
          automaticallyImplyLeading: false,
          height: 30,
          title: const DragToMoveArea(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Cartridge'),
            ]),
          ),
          actions: Stack(
            children: [
              Row(
                children: [
                  Expanded(child: Container()),
                  IconButton(
                    icon: const PhosphorIcon(
                        PhosphorIconsRegular.arrowClockwise,
                        size: 16),
                    onPressed: onRefresh,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const PhosphorIcon(PhosphorIconsRegular.gearSix,
                        size: 12),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const SettingDialog(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
        content: material.Material(
          color: Colors.transparent,
          child: child,
        ),
      );
    }

    if (Platform.isMacOS) {
      return buildMacOSTitleBar(context, ref);
    }

    return buildWindowsTitleBar(context, ref);
  }
}
