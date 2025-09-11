import 'dart:math';
import 'package:cartridge/theme/theme.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:cartridge/features/cartridge/slot_machine/slot_machine.dart';

class SlotView extends ConsumerStatefulWidget {
  const SlotView({
    super.key,
    required this.items,
    required this.onEdited,
    required this.onDeleted,
  });

  final List<String> items;
  final void Function(List<String> newItems) onEdited;
  final VoidCallback onDeleted;

  @override
  ConsumerState<SlotView> createState() => _SlotViewState();
}

class _SlotViewState extends ConsumerState<SlotView> {
  final FixedExtentScrollController _wheel = FixedExtentScrollController();
  final _rng = Random();
  bool _hover = false;
  bool _spinning = false;
  bool _stepping = false;

  int _lastSpinTick = -1; // 자동 스핀 방지용

  List<String> get _effectiveItems {
    final loc = AppLocalizations.of(context);
    return widget.items.isEmpty ? <String>[loc.slot_default] : widget.items;
  }

  int get _lenForSpin => widget.items.isEmpty ? 1 : widget.items.length;

  void _start() {
    if (!mounted || _spinning) return;

    final len = _lenForSpin;
    final current = _wheel.selectedItem % len;
    _wheel.jumpToItem(current);

    final target = current + (_rng.nextInt(len * 200) + len * 5);
    final ms = (2400 * ((_rng.nextDouble() + 1) / 2)).toInt();

    _spinning = true;
    _wheel
        .animateToItem(
      target,
      duration: Duration(milliseconds: ms),
      curve: Curves.easeInOutBack,
    )
        .whenComplete(() {
      if (!mounted) return;
      setState(() => _spinning = false);
    });
  }

  @override
  void initState() {
    super.initState();
    _lastSpinTick = ref.read(spinAllTickProvider);
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  Future<void> _animateOneStep(int dir, double itemExtent) async {
    if (!mounted || _spinning || _stepping || dir == 0) return;
    _stepping = true;
    try {
      final pos = _wheel.position;
      final curIndex = _wheel.selectedItem;
      final curOffset = pos.pixels;

      final targetIndex = curIndex + dir;
      final targetOffset = targetIndex * itemExtent;

      // 1) 프리롤
      final midOffset = curOffset + dir * itemExtent * 0.35;
      await pos.animateTo(
        midOffset,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeInBack,
      );

      // 2) 세틀
      await pos.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
      );
    } finally {
      if (mounted) _stepping = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final fTheme = FluentTheme.of(context);

    final sem = ref.watch(themeSemanticsProvider);

    // ── 토큰 기반 치수 계산 ─────────────────────────────────────────
    const double unit = AppSpacing.lg;
    final sizeClass = context.sizeClass;

    final double panelWidth = switch (sizeClass) {
      SizeClass.lg || SizeClass.xl => unit * 14,
      SizeClass.md => unit * 13,
      _ => unit * 12,
    };

    final double itemExtent = AppSpacing.lg * 8; // 한 칸 높이
    final double contentWidth = panelWidth - unit * 2; // 좌우 여백 고려
    final double viewportHeight = itemExtent * 2.8;

    final dividerColor = fTheme.dividerColor;

    // 글로벌 스핀 트리거
    final tick = ref.watch(spinAllTickProvider);
    if (tick != _lastSpinTick) {
      _lastSpinTick = tick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
    }

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(
        width: panelWidth,
        height: viewportHeight,
      ),
      child: Listener(
        onPointerSignal: (evt) {
          if (evt is PointerScrollEvent && !_spinning) {
            final dir = evt.scrollDelta.dy == 0 ? 0 : (evt.scrollDelta.dy > 0 ? 1 : -1);
            _animateOneStep(dir, itemExtent);
          }
        },
        child: Stack(
          children: [
            // ── Wheel ────────────────────────────────────────────────────────
            ListWheelScrollView.useDelegate(
              controller: _wheel,
              itemExtent: itemExtent,
              physics: const FixedExtentScrollPhysics(
                parent: NeverScrollableScrollPhysics(),
              ),
              diameterRatio: 1.15,
              overAndUnderCenterOpacity: 0.4,
              childDelegate: ListWheelChildLoopingListDelegate(
                children: _effectiveItems
                    .map(
                      (value) => SlotItem(
                    width: contentWidth,
                    height: itemExtent,
                    text: value,
                  ),
                )
                    .toList(),
              ),
            ),

            // ── Overlay + Controls ───────────────────────────────────────────
            Center(
              child: SizedBox(
                width: contentWidth,
                height: itemExtent,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => setState(() => _hover = true),
                  onExit: (_) => setState(() => _hover = false),
                  child: ClipRect( // radius 제거
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // hover 오버레이 (withAlpha 사용)
                        IgnorePointer(
                          ignoring: true,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _hover ? 1 : 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: fTheme.cardColor.withAlpha(220),
                                border: Border.all(color: dividerColor),
                              ),
                            ),
                          ),
                        ),

                        // 컨트롤 버튼
                        Align(
                          alignment: Alignment.center,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 120),
                            opacity: _hover ? 1 : 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Tooltip(
                                  message: loc.roulette_start_button,
                                  style: const TooltipThemeData(waitDuration: Duration.zero),
                                  child: IconButton(
                                    icon: const Icon(FluentIcons.sync, size: 24),
                                    onPressed: _spinning ? null : _start,
                                  ),
                                ),
                                Gaps.w12,
                                Tooltip(
                                  message: loc.common_edit,
                                  style: const TooltipThemeData(waitDuration: Duration.zero),
                                  child: IconButton(
                                    icon: const Icon(FluentIcons.edit, size: 24),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) => SlotDialog(
                                        items: widget.items,
                                        onEdit: widget.onEdited,
                                      ),
                                    ),
                                  ),
                                ),
                                Gaps.w12,
                                Tooltip(
                                  message: loc.common_delete,
                                  style: const TooltipThemeData(waitDuration: Duration.zero),
                                  child: IconButton(
                                    icon: Icon(
                                      FluentIcons.delete,
                                      color: sem.danger.fg, // theme.sem → sem.xxx로 수정
                                      size: 24,
                                    ),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (context) => ContentDialog(
                                        title: Text(loc.slot_delete_title),
                                        content: Text(loc.slot_delete_message),
                                        actions: [
                                          Button(
                                            onPressed: () => Navigator.pop(context),
                                            child: Text(loc.common_cancel),
                                          ),
                                          FilledButton(
                                            style: ButtonStyle(
                                              backgroundColor: WidgetStateProperty.all(sem.danger.fg),
                                            ),
                                            onPressed: () {
                                              Navigator.pop(context);
                                              widget.onDeleted();
                                            },
                                            child: Text(loc.common_delete),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
