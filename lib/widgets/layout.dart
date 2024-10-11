import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/quick_bar.dart';
import 'package:cartridge/widgets/dialogs/setting_dialog.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class Layout extends ConsumerWidget {
  const Layout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);

    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        title: DragToMoveArea(
          child: Row(children: [
            const Text('Cartridge'),
            const SizedBox(width: 8.0),
            MediaQuery.of(context).size.width <= 800
                ? const QuickBar()
                : Container(),
          ]),
        ),
        actions: Stack(
          children: [
            MediaQuery.of(context).size.width > 800
                ? const Center(child: QuickBar())
                : Container(),
            Row(
              children: [
                Expanded(child: Container()),
                IconButton(
                  icon: const Icon(FluentIcons.refresh, size: 20),
                  onPressed: () => store.reloadMods(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(FluentIcons.settings, size: 20),
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
                    // brightness: theme.brightness,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      content: child,
    );
  }
}
