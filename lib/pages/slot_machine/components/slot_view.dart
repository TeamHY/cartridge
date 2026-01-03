import 'dart:math';
import 'dart:ui';

import 'package:cartridge/components/dialogs/mod_group_selector_dialog.dart';
import 'package:cartridge/pages/slot_machine/components/slot_item.dart';
import 'package:cartridge/providers/slot_machine_provider.dart';
import 'package:cartridge/providers/store_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class SlotViewController {
  SlotViewController({this.start});

  void Function()? start;
}

class SlotView extends ConsumerStatefulWidget {
  const SlotView({
    super.key,
    required this.items,
    required this.controller,
    required this.onEdited,
    required this.onDeleted,
  });

  final List<String> items;
  final SlotViewController controller;
  final void Function(List<String> newItems) onEdited;
  final void Function() onDeleted;

  @override
  ConsumerState<SlotView> createState() => _SlotViewState();
}

class _SlotViewState extends ConsumerState<SlotView> {
  final FixedExtentScrollController _controller = FixedExtentScrollController();
  bool _isHovered = false;

  List<String> get resolvedItems {
    final slotMachine = ref.read(slotMachineProvider);
    final store = ref.read(storeProvider);

    if (slotMachine.isGroupSlot(widget.items)) {
      final groupName = slotMachine.getGroupName(widget.items);
      if (groupName != null && store.groups.containsKey(groupName)) {
        final groupMods = store.groups[groupName];
        if (groupMods != null && groupMods.isNotEmpty) {
          return groupMods.toList();
        }
      }
      return [groupName ?? 'Empty Group'];
    }
    return widget.items;
  }

  void onStart() {
    final items = resolvedItems;
    _controller.jumpToItem(_controller.selectedItem % items.length);

    _controller.animateToItem(
      Random().nextInt(items.length * 200) + items.length * 5,
      duration: Duration(
        milliseconds: (3000 * ((Random().nextDouble() + 1) / 2)).toInt(),
      ),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void initState() {
    super.initState();

    widget.controller.start = onStart;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final items = resolvedItems;
    final slotMachine = ref.watch(slotMachineProvider);
    final isGroup = slotMachine.isGroupSlot(widget.items);

    return SizedBox(
      width: 180,
      height: 320,
      child: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 180,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 100,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1,
            overAndUnderCenterOpacity: 0.2,
            childDelegate: ListWheelChildLoopingListDelegate(
                children: items
                    .map((value) =>
                        SlotItem(width: 180, height: 100, text: value))
                    .toList()),
          ),
          if (isGroup)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    slotMachine.getGroupName(widget.items) ?? '',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          Center(
            child: SizedBox(
              width: 180,
              height: 100,
              child: MouseRegion(
                onHover: (event) => setState(() => _isHovered = true),
                onExit: (event) => setState(() => _isHovered = false),
                child: ClipRect(
                  child: TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 100),
                      tween: Tween<double>(begin: 0, end: _isHovered ? 1 : 0),
                      curve: Curves.easeInOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.85),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(FluentIcons.sync),
                                    onPressed: onStart,
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(FluentIcons.edit),
                                    onPressed: () async {
                                      if (isGroup) {
                                        final newGroupName =
                                            await showDialog<String>(
                                          context: context,
                                          builder: (context) =>
                                              const ModGroupSelectorDialog(),
                                        );

                                        if (newGroupName != null) {
                                          widget.onEdited(
                                              ['${groupPrefix}$newGroupName']);
                                        }
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return SlotDialog(
                                              items: widget.items,
                                              onEdit: widget.onEdited,
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      FluentIcons.delete,
                                      color: Colors.red.dark,
                                    ),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) {
                                        return ContentDialog(
                                          title: Text(loc.slot_delete_title),
                                          content:
                                              Text(loc.slot_delete_message),
                                          actions: [
                                            Button(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(loc.common_cancel),
                                            ),
                                            FilledButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    ButtonState.all<Color>(
                                                        Colors.red.dark),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                widget.onDeleted();
                                              },
                                              child: Text(loc.common_delete),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SlotDialog extends ConsumerStatefulWidget {
  const SlotDialog({
    super.key,
    required this.items,
    required this.onEdit,
  });

  final List<String> items;
  final Function(List<String> newItems) onEdit;

  @override
  ConsumerState<SlotDialog> createState() => _SlotDialogState();
}

class _SlotDialogState extends ConsumerState<SlotDialog> {
  late List<String> newItems;

  @override
  void initState() {
    super.initState();

    newItems = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ContentDialog(
      title: Text(loc.slot_edit_title),
      constraints: const BoxConstraints(maxWidth: 368, maxHeight: 600),
      content: SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < newItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(FluentIcons.remove),
                      onPressed: () => setState(() {
                        newItems.removeAt(i);
                      }),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 298,
                      child: TextBox(
                        onChanged: (value) {
                          // setState를 의도해서 사용하지 않았음
                          newItems[i] = value;
                        },
                        controller: TextEditingController(
                          text: newItems[i],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(FluentIcons.add),
              onPressed: () {
                setState(() {
                  newItems.add('');
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            widget.onEdit(newItems);
            Navigator.pop(context);
          },
          child: Text(loc.common_apply),
        ),
      ],
    );
  }
}
