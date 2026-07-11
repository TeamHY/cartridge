import 'dart:io';

import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class Layout extends ConsumerWidget {
  const Layout({
    super.key,
    required this.child,
    required this.onHomePressed,
    required this.onSettingPressed,
  });

  final Widget child;

  final VoidCallback onHomePressed;
  final VoidCallback onSettingPressed;

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
        content: Column(
          children: [
            SizedBox(
              height: 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: DragToMoveArea(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Text('Cartridge'),
                        ),
                      ),
                    ),
                  ),
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
                    onPressed: onSettingPressed,
                  ),
                  const SizedBox(width: 4),
                  const SizedBox(
                    width: 138,
                    height: 32,
                    child: WindowCaption(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: material.Material(
                color: Colors.transparent,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildMacOSTitleBar(BuildContext context, WidgetRef ref) {
      return NavigationView(
        content: Column(
          children: [
            SizedBox(
              height: 30,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DragToMoveArea(
                      child: Center(
                        child: Text('Cartridge'),
                      ),
                    ),
                  ),
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
                        onPressed: onSettingPressed,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: material.Material(
                color: Colors.transparent,
                child: child,
              ),
            ),
          ],
        ),
      );
    }

    if (Platform.isMacOS) {
      return buildMacOSTitleBar(context, ref);
    }

    return buildWindowsTitleBar(context, ref);
  }
}
