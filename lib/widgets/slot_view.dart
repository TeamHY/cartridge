import 'dart:math';
import 'dart:ui';

import 'package:cartridge/widgets/slot_item.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SlotViewController {
  SlotViewController({this.start});

  void Function()? start;
}

class SlotView extends StatefulWidget {
  const SlotView({
    super.key,
    required this.items,
    required this.controller,
    required this.onDeleted,
    required this.onEdited,
  });

  final List<String> items;
  final SlotViewController controller;
  final void Function() onDeleted;
  final void Function(List<String> newItems) onEdited;

  @override
  State<SlotView> createState() => _SlotViewState();
}

class _SlotViewState extends State<SlotView> {
  FixedExtentScrollController _controller = FixedExtentScrollController();
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    widget.controller.start = () {
      _controller.jumpToItem(_controller.selectedItem % widget.items.length);

      _controller.animateToItem(
        Random().nextInt(widget.items.length * 200) + widget.items.length * 5,
        duration: Duration(
          milliseconds: (3000 * ((Random().nextDouble() + 1) / 2)).toInt(),
        ),
        curve: Curves.easeInOutCubic,
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 200,
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: 48,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 1,
            overAndUnderCenterOpacity: 0.2,
            childDelegate: ListWheelChildLoopingListDelegate(
                children: widget.items
                    .map((value) =>
                        SlotItem(width: 120, height: 48, text: value))
                    .toList()),
          ),
          MouseRegion(
            onHover: (event) => setState(() => _isHovered = true),
            onExit: (event) => setState(() => _isHovered = false),
            child: ClipRect(
              child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 100),
                  tween: Tween<double>(begin: 0, end: _isHovered ? 1 : 0),
                  curve: Curves.easeInOutCubic,
                  builder: (context, value, child) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: value * 4,
                        sigmaY: value * 4,
                      ),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          color: const Color.fromRGBO(245, 248, 252, 0.5),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(FluentIcons.edit),
                                  onPressed: () => showDialog(
                                    context: context,
                                    builder: (context) {
                                      return SlotDialog(
                                        items: widget.items,
                                        onEdit: widget.onEdited,
                                      );
                                    },
                                  ),
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
                                        title: const Text("슬롯 삭제"),
                                        content: const Text(
                                            '슬롯을 삭제하면 복구할 수 없습니다. 정말 삭제하시겠습니까?'),
                                        actions: [
                                          Button(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('취소'),
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
                                            child: const Text('삭제'),
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
                      ),
                    );
                  }),
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
    return ContentDialog(
      title: const Text("슬롯 수정"),
      content: Center(
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
          child: const Text("취소"),
        ),
        FilledButton(
          onPressed: () {
            widget.onEdit(newItems);
            Navigator.pop(context);
          },
          child: const Text("적용"),
        ),
      ],
    );
  }
}
