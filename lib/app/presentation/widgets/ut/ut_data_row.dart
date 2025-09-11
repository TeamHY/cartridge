import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart' show kPrimaryButton;

import 'ut_table.dart';

class UTDataRow extends StatefulWidget {
  const UTDataRow({
    super.key,
    required this.height,
    required this.columnWidths,
    required this.cells,
    this.selectionEnabled = true,
    this.selected = false,
    this.onChanged,
    this.trailing,
    this.reserveLeading = true,
    this.reserveTrailing = false,
    this.leadingWidth = kUTLeadingColWidth,
    this.focused = false,
    this.onTapRow,
    this.isDragSelecting = false,
    this.onBeginDragSelect,
    this.onEndDragSelect,
    this.onDragEnterLeading,
    this.rowIndex,
    this.baseBackground,
  }) : assert(columnWidths.length == cells.length,
  'columnWidths.length must equal cells.length');

  final double height;
  final List<double> columnWidths;
  final List<Widget> cells;

  final bool selectionEnabled;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  final Widget? trailing;
  final bool reserveLeading;
  final bool reserveTrailing;
  final double leadingWidth;

  final bool focused;
  final VoidCallback? onTapRow;

  final bool isDragSelecting;
  final void Function(bool target)? onBeginDragSelect;
  final VoidCallback? onEndDragSelect;
  final VoidCallback? onDragEnterLeading;

  final int? rowIndex; // ★
  final Color? baseBackground; // ★

  @override
  State<UTDataRow> createState() => _UTDataRowState();
}

class _UTDataRowState extends State<UTDataRow> {
  bool _hover = false;
  bool _pressed = false;

  List<double> _fitToWidth(double avail, List<double> widths) {
    if (widths.isEmpty || avail <= 0) return widths;
    final sum = widths.fold<double>(0, (a, b) => a + b);
    final f = sum > avail ? (avail / sum) : 1.0;
    final scaled = [for (final w in widths) w * f];
    double acc = 0;
    for (int i = 0; i < scaled.length - 1; i++) {
      scaled[i] = scaled[i].clamp(0, avail);
      acc += scaled[i];
    }
    scaled[scaled.length - 1] = (avail - acc).clamp(0, avail);
    return scaled;
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final tt = UTTableTheme.of(context);

    final hoverBg = tt.rowHoverColor(fTheme);
    final pressBg = tt.rowPressColor(fTheme);
    final selBg   = tt.rowSelectedColor(fTheme);

    // base background (custom > zebra), sits below hover/press/selected
    Color? baseBg = widget.baseBackground;
    if (baseBg == null && tt.zebraEnabled && (widget.rowIndex ?? 0).isOdd) {
      baseBg = tt.zebraColor(fTheme);
    }

    Color? bg = baseBg;
    if (widget.selected) {
      bg = selBg;
    } else if (_pressed) {
      bg = pressBg;
    } else if (_hover) {
      bg = hoverBg;
    }

    final focusBorder = widget.focused
        ? Border(left: BorderSide(color: fTheme.accentColor.normal, width: tt.focusBarWidth))
        : null;

    final showLeading = widget.selectionEnabled && widget.reserveLeading;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel:     () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTapRow?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          height: widget.height,
          color: bg,
          foregroundDecoration: BoxDecoration(border: focusBorder),
          child: Row(
            children: [
              if (showLeading)
                SizedBox(
                  width: widget.leadingWidth,
                  child: Listener(
                    onPointerDown: (e) {
                      if (e.buttons == kPrimaryButton) {
                        widget.onBeginDragSelect?.call(!widget.selected);
                        widget.onDragEnterLeading?.call();
                      }
                    },
                    onPointerUp: (_) => widget.onEndDragSelect?.call(),
                    child: MouseRegion(
                      onEnter: (_) => widget.onDragEnterLeading?.call(),
                      child: Center(
                        child: Checkbox(
                          checked: widget.selected,
                          onChanged: (v) {
                            if (widget.isDragSelecting) return;
                            widget.onChanged?.call(v ?? false);
                          },
                        ),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, cons) {
                    final widths = _fitToWidth(cons.maxWidth, widget.columnWidths);
                    return Row(
                      children: [
                        for (var i = 0; i < widths.length; i++)
                          ClipRect(
                            child: SizedBox(
                              width: widths[i],
                              child: _CellPad(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minWidth: 0),
                                  child: widget.cells[i],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),

              if (widget.reserveTrailing)
                SizedBox(
                  width: kUTTrailingColWidth,
                  child: Center(child: widget.trailing ?? const SizedBox.shrink()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CellPad extends StatelessWidget {
  const _CellPad({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final tt = UTTableTheme.of(context);

    return ClipRect(
      child: Container(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: tt.cellHPadding),
        child: DefaultTextStyle(
          style: (fTheme.typography.body ?? const TextStyle()).copyWith(
            overflow: TextOverflow.ellipsis,
          ),
          maxLines: 1,
          child: child,
        ),
      ),
    );
  }
}

