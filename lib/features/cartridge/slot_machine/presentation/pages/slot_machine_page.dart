import 'package:cartridge/app/presentation/widgets/status_card.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:cartridge/app/presentation/content_scaffold.dart';
import 'package:cartridge/app/presentation/empty_state.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/theme/theme.dart';

class SlotMachinePage extends ConsumerStatefulWidget {
  const SlotMachinePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SlotMachinePageState();
}

class _SlotMachinePageState extends ConsumerState<SlotMachinePage>
    with WindowListener {
  final _hScroll = ScrollController();
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _hScroll.dispose();
    super.dispose();
  }

  void _onAddSlot({required bool left}) {
    final loc = AppLocalizations.of(context);
    final controller = ref.read(slotMachineControllerProvider.notifier);

    if (left) {
      controller.addLeft(defaultText: loc.slot_default);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hScroll.hasClients) {
          _hScroll.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      controller.addRight(defaultText: loc.slot_default);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hScroll.hasClients) {
          final max = _hScroll.position.maxScrollExtent;
          _hScroll.animateTo(
            max,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Widget _addSlotButton(
      BuildContext context, {
        bool large = false,
        required bool left,
        bool enabled = true,
      }) {
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);
    final loc = AppLocalizations.of(context);

    final double size = large ? AppSpacing.xl * 1.5 : AppSpacing.lg * 1.25;

    return SizedBox(
      width: size,
      height: size,
      child: Tooltip(
        message: loc.slot_add_item,
        style: const TooltipThemeData(waitDuration: Duration.zero),
        child: IconButton(
          icon: Icon(
            FluentIcons.add,
            size: size * 0.85,
            color: enabled ? sem.success.fg : null,
          ),
          iconButtonMode: IconButtonMode.large,
          onPressed: enabled ? () => _onAddSlot(left: left) : null,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            backgroundColor: WidgetStateProperty.all(fTheme.cardColor),
            shape: WidgetStateProperty.all(RoundedRectangleBorder(
              borderRadius: AppShapes.chip,
            )),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(slotMachineControllerProvider);
    final controller = ref.read(slotMachineControllerProvider.notifier);
    final fTheme = FluentTheme.of(context);
    final sem = ref.watch(themeSemanticsProvider);
    final loc = AppLocalizations.of(context);

    return ScaffoldPage(
      header: const ContentHeaderBar.none(),
      content: ContentShell(
        child: _ViewportCenter(
          // 가로/세로 모두 중앙
          child: slotsAsync.when(
            loading: () => const ProgressRing(),
            error: (_, __) {
              return StatusCard(
                title: loc.slot_error_title,
                description: loc.slot_error_desc,
                primaryLabel: loc.common_retry,
                onPrimary: () => ref.invalidate(slotMachineControllerProvider),
              );
            },
            data: (slots) {
              if (slots.isEmpty) {
                return SizedBox.expand(
                  child: Center(
                    child: EmptyState.withDefault404(
                      title: loc.slot_empty_message,
                      primaryLabel: loc.slot_add_item,
                      onPrimary: () => _onAddSlot(left: true),
                    ),
                  ),
                );
              }

              final rowChildren = <Widget>[
                _addSlotButton(context, left: true),
                Gaps.w8,
                for (var i = 0; i < slots.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: SlotView(
                      key: ValueKey(slots[i].id),
                      items: slots[i].items,
                      onDeleted: () => controller.removeSlot(slots[i].id),
                      onEdited: (newItems) => controller.setSlotItems(slots[i].id, newItems),
                    ),
                  ),
                Gaps.w8,
                _addSlotButton(context, left: false),
              ];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 가로 스크롤 영역
                  MouseRegion(
                    cursor: _dragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart: (_) => setState(() => _dragging = true),
                      onHorizontalDragUpdate: (details) {
                        if (!_hScroll.hasClients) return;
                        final max = _hScroll.position.maxScrollExtent;
                        final next = (_hScroll.offset - details.delta.dx).clamp(0.0, max);
                        _hScroll.jumpTo(next);
                      },
                      onHorizontalDragEnd: (_) => setState(() => _dragging = false),
                      child: SingleChildScrollView(
                        controller: _hScroll,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Row(children: rowChildren),
                      ),
                    ),
                  ),

                  Gaps.h16,

                  // 전체 스핀 버튼
                  Tooltip(
                    message: loc.roulette_start_button,
                    style: const TooltipThemeData(waitDuration: Duration.zero),
                    child: SizedBox(
                      width: AppSpacing.xl * 2.25,
                      height: AppSpacing.xl * 2.25,
                      child: IconButton(
                        icon: Icon(FluentIcons.sync, size: AppSpacing.xl * 1.2, color: sem.info.fg),
                        iconButtonMode: IconButtonMode.large,
                        onPressed: () {
                          final notifier = ref.read(spinAllTickProvider.notifier);
                          notifier.state = notifier.state + 1;
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(fTheme.cardColor),
                          shape: WidgetStateProperty.all(RoundedRectangleBorder(
                            borderRadius: AppShapes.card,
                          )),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 스크롤 컨테이너 안에서도 세로 중앙 정렬이 되도록 하는 래퍼
class _ViewportCenter extends StatelessWidget {
  const _ViewportCenter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final reserved = AppSpacing.xl * 6;
    final viewportH = (screenH - reserved).clamp(0.0, double.infinity);

    return LayoutBuilder(
      builder: (_, constraints) {
        final h = constraints.hasBoundedHeight && constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : viewportH;

        return ConstrainedBox(
          constraints: BoxConstraints.tightFor(
            height: h,
            width: constraints.hasBoundedWidth ? constraints.maxWidth : double.infinity,
          ),
          child: Center(child: child),
        );
      },
    );
  }
}
