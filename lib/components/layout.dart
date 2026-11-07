import 'dart:io';

import 'package:cartridge/components/music_island.dart';
import 'package:cartridge/providers/music_player_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class Layout extends ConsumerWidget {
  const Layout({
    super.key,
    required this.child,
    required this.onHomePressed,
    required this.onSettingPressed,
    required this.onMusicPressed,
    required this.navigation,
  });

  final Widget child;
  final Widget navigation;

  final VoidCallback onHomePressed;
  final VoidCallback onSettingPressed;
  final VoidCallback onMusicPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final musicPlayer = ref.watch(musicPlayerProvider);
    final c = AppColors.of(context);

    void onRefresh() {
      store.reloadMods();
      musicPlayer.reloadPlaylist();
    }

    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [navigation, Expanded(child: child)],
    );

    Widget buildWindowsTitleBar(BuildContext context, WidgetRef ref) {
      return ColoredBox(
        color: c.bg,
        child: Column(
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
                  AppIconButton(
                    icon:
                        const PhosphorIcon(PhosphorIconsRegular.arrowClockwise),
                    size: 28,
                    onPressed: onRefresh,
                  ),
                  const SizedBox(width: 4),
                  AppIconButton(
                    icon: const PhosphorIcon(PhosphorIconsRegular.gearSix),
                    size: 28,
                    onPressed: onSettingPressed,
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 138,
                    height: 32,
                    child: WindowCaption(
                      brightness: Theme.of(context).brightness,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    Widget buildMacOSTitleBar(BuildContext context, WidgetRef ref) {
      return ColoredBox(
        color: c.bg,
        child: Column(
          children: [
            SizedBox(
              height: 30,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: DragToMoveArea(child: SizedBox.expand()),
                  ),
                  Row(
                    children: [
                      Expanded(child: Container()),
                      AppIconButton(
                        icon: const PhosphorIcon(
                            PhosphorIconsRegular.arrowClockwise),
                        size: 26,
                        onPressed: onRefresh,
                      ),
                      const SizedBox(width: 4),
                      AppIconButton(
                        icon: const PhosphorIcon(PhosphorIconsRegular.gearSix),
                        size: 26,
                        iconSize: 12,
                        onPressed: onSettingPressed,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Platform.isMacOS
            ? buildMacOSTitleBar(context, ref)
            : buildWindowsTitleBar(context, ref),
        Positioned.fill(child: MusicIsland(onOpenMusic: onMusicPressed)),
      ],
    );
  }
}
