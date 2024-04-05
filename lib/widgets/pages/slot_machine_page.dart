import 'package:cartridge/providers/slot_machine_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:cartridge/widgets/slot_view.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

class SlotMachinePage extends ConsumerStatefulWidget {
  const SlotMachinePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SlotMachinePageState();
}

class _SlotMachinePageState extends ConsumerState<SlotMachinePage>
    with WindowListener {
  List<SlotViewController> controllers = [];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);

    ref.read(storeProvider.notifier).checkAstroVersion();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowFocus() {
    ref.read(storeProvider.notifier).checkAstroVersion();
  }

  @override
  Widget build(BuildContext context) {
    final slotMachine = ref.watch(slotMachineProvider);

    final List<Widget> children = [];

    children.add(const SizedBox(width: 40, height: 40));

    for (var i = 0; i < slotMachine.slots.length; i++) {
      final controller = SlotViewController();

      controllers.add(controller);

      children.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: SlotView(
          items: slotMachine.slots[i],
          controller: controller,
          onDeleted: () => slotMachine.removeSlot(i),
          onEdited: (List<String> newItems) => slotMachine.setSlot(i, newItems),
        ),
      ));
    }

    children.add(SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: const Icon(FluentIcons.add),
        onPressed: () => slotMachine.addSlot(),
      ),
    ));

    return NavigationView(
      content: Stack(
        children: [
          const DragToMoveArea(child: SizedBox.expand()),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: children,
                  ),
                ),
                const SizedBox(height: 16),
                IconButton(
                  icon: const Icon(
                    FluentIcons.sync,
                    size: 20,
                  ),
                  iconButtonMode: IconButtonMode.large,
                  onPressed: () => controllers.forEach((e) => e.start?.call()),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                iconButtonMode: IconButtonMode.large,
                icon: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(
                    FluentIcons.back,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(
                width: 138,
                height: 50,
                child: WindowCaption(
                  brightness: Brightness.dark,
                  backgroundColor: Colors.transparent,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
