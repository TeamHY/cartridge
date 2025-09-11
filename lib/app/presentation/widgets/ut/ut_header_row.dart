import 'package:fluent_ui/fluent_ui.dart';

import 'package:cartridge/theme/theme.dart';
import 'ut_table.dart';

class UTHeaderRow extends StatelessWidget {
  const UTHeaderRow({
    super.key,
    required this.height,
    required this.columns,
    required this.triState, // true/false/null
    this.selectionEnabled = true,
    this.onToggleAll,
    this.padding = EdgeInsets.zero,
    this.backgroundColor,
    this.resolvedWidths,
    this.leadingWidth = kUTLeadingColWidth,
    this.reserveTrailing = false,
    this.trailingWidth = kUTTrailingColWidth,
    this.sortColumnId,
    this.ascending = true,
    this.onTapSort,
    this.onResizeColumn,
    this.onClearColumnResize,
    this.trailing,
  });

  final double height;
  final List<UTColumnSpec> columns;
  final bool? triState;
  final bool selectionEnabled;
  final ValueChanged<bool>? onToggleAll;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final List<double>? resolvedWidths;
  final double leadingWidth;
  final bool reserveTrailing;
  final double trailingWidth;
  final String? sortColumnId;
  final bool ascending;
  final void Function(String columnId)? onTapSort;
  final Widget? trailing;

  /// (columnId, newWidthPx)
  final void Function(String columnId, double newWidth)? onResizeColumn;

  /// 더블클릭으로 폭 override 초기화
  final void Function(String columnId)? onClearColumnResize;

  Color _dividerFallback(FluentThemeData theme) {
    final base = theme.cardColor;
    final alpha = theme.brightness == Brightness.dark ? 56 : 24;
    final themeDivider = (theme.dividerTheme.decoration is BoxDecoration)
        ? (theme.dividerTheme.decoration as BoxDecoration?)?.color
        : null;
    return themeDivider ?? base.withAlpha(alpha);
  }

  Color _blendSurface(FluentThemeData theme, double t) {
    final base = theme.scaffoldBackgroundColor;
    final overlay = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    return Color.lerp(base, overlay, t)!;
  }

  List<double> _fitToWidth(double avail, List<double> widths) {
    if (widths.isEmpty || avail <= 0) return widths;
    final sum = widths.fold<double>(0, (a, b) => a + b);
    if (sum <= avail) return widths;

    final f = avail / sum;
    final scaled = [for (final w in widths) w * f];
    double acc = 0;
    for (int i = 0; i < scaled.length - 1; i++) {
      acc += scaled[i];
    }
    scaled[scaled.length - 1] = (avail - acc).clamp(0, avail);
    return scaled;
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final divider = _dividerFallback(fTheme);
    final tt = UTTableTheme.of(context);

    return Container(
      height: height,
      color: backgroundColor ?? fTheme.scaffoldBackgroundColor,
      child: Row(
        children: [
          SizedBox(
            width: leadingWidth,
            child: Center(
              child: selectionEnabled
                  ? Checkbox(
                checked: triState,
                onChanged: onToggleAll == null
                    ? null
                    : (_) {
                  final want = (triState == true) ? false : true;
                  onToggleAll!(want);
                },
              )
                  : const SizedBox.shrink(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: padding,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final List<double> widths;
                  if (resolvedWidths != null) {
                    widths = resolvedWidths!;
                  } else {
                    final base =
                    UTWidthResolver.resolve(columns, constraints.maxWidth);
                    widths = _fitToWidth(constraints.maxWidth, base);
                  }

                  return Row(
                    children: [
                      for (var i = 0; i < columns.length; i++)
                        _HeaderCell(
                          width: widths[i],
                          spec: columns[i],
                          isSortCol: sortColumnId == columns[i].id,
                          ascending: ascending,
                          rightDividerColor: i == columns.length - 1
                              ? divider.withAlpha(0)
                              : divider,
                          onTap: (columns[i].sortable && onTapSort != null)
                              ? () => onTapSort!(columns[i].id)
                              : null,
                          onResize: (columns[i].resizable && onResizeColumn != null)
                              ? (newW) => onResizeColumn!(columns[i].id, newW)
                              : null,
                          onClear: (columns[i].resizable && onClearColumnResize != null)
                              ? () => onClearColumnResize!(columns[i].id)
                              : null,
                          // hover/press 색
                          hoverColor: _blendSurface(
                            fTheme,
                            fTheme.brightness == Brightness.dark ? 0.10 : 0.08,
                          ),
                          pressColor: _blendSurface(
                            fTheme,
                            fTheme.brightness == Brightness.dark ? 0.18 : 0.14,
                          ),
                          horizontalPadding: tt.cellHPadding,
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (reserveTrailing)
            SizedBox(
              width: trailingWidth,
              child: Align(
                alignment: Alignment.center,
                child: trailing ?? const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatefulWidget {
  const _HeaderCell({
    required this.width,
    required this.spec,
    required this.isSortCol,
    required this.ascending,
    required this.rightDividerColor,
    required this.horizontalPadding,
    this.onTap,
    this.onResize, // newWidth(px)
    this.onClear,  // 더블탭 리셋
    this.hoverColor,
    this.pressColor,
  });

  final double width;
  final UTColumnSpec spec;
  final bool isSortCol;
  final bool ascending;
  final Color rightDividerColor;
  final double horizontalPadding;
  final VoidCallback? onTap;
  final void Function(double newWidth)? onResize;
  final VoidCallback? onClear;

  final Color? hoverColor;
  final Color? pressColor;

  @override
  State<_HeaderCell> createState() => _HeaderCellState();
}

class _HeaderCellState extends State<_HeaderCell> {
  bool _dragging = false;
  double _baseWidth = 0;
  double _accumDx = 0;

  bool _hoverContent = false;
  bool _pressedContent = false;
  bool _hoverHandle = false;

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _baseWidth = widget.width;
    _accumDx = 0;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (widget.onResize == null) return;
    _accumDx += d.delta.dx;
    final min = widget.spec.minPx ?? 60;
    final max = widget.spec.maxPx ?? double.infinity;
    final next = (_baseWidth + _accumDx).clamp(min, max).toDouble();
    widget.onResize!(next);
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
  }

  @override
  void didUpdateWidget(covariant _HeaderCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) {
      _baseWidth = widget.width;
      _accumDx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clickable = widget.spec.sortable && widget.onTap != null;

    Icon? chevron;
    if (widget.spec.sortable) {
      chevron = widget.isSortCol
          ? Icon(
        widget.ascending
            ? FluentIcons.caret_solid_up
            : FluentIcons.caret_solid_down,
        size: 10,
      )
          : null;
    }

    // 내용 전체 영역을 채우는 배경(가시성 ↑)
    final contentBg = !_hoverHandle && clickable
        ? (_pressedContent
        ? widget.pressColor
        : (_hoverContent ? widget.hoverColor : null))
        : null;

    // header 위젯이 있으면 우선, 없으면 title 텍스트
    final titleText = Text(
      widget.spec.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final headerChild = widget.spec.header ?? titleText;
    final header = widget.spec.tooltip == null
        ? headerChild
        : Tooltip(message: widget.spec.tooltip!, child: headerChild);

    // 리사이즈 핸들(오른쪽 8px)
    final dividerColor = _hoverHandle
        ? widget.rightDividerColor.withAlpha(
        (((widget.rightDividerColor.a * 255.0).round()) + 40).clamp(0, 255))
        : widget.rightDividerColor;

    final handle = (widget.onResize == null && widget.onClear == null)
        ? const SizedBox.shrink()
        : MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hoverHandle = true),
      onExit: (_) => setState(() => _hoverHandle = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: widget.onResize == null ? null : _onDragStart,
        onHorizontalDragUpdate:
        widget.onResize == null ? null : _onDragUpdate,
        onHorizontalDragEnd: widget.onResize == null ? null : _onDragEnd,
        onDoubleTap: widget.onClear,
        child: Container(
          width: 8,
          height: double.infinity,
          color: Colors.transparent,
          alignment: Alignment.centerRight,
          child: Container(
            width: 1,
            height: double.infinity,
            color: dividerColor,
          ),
        ),
      ),
    );

    return SizedBox(
      width: widget.width,
      child: Row(
        children: [
          // 내용: 본문과 같은 좌/우 패딩 적용으로 좌측 정렬선 맞춤
          Expanded(
            child: MouseRegion(
              cursor: clickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
              onEnter: (_) => setState(() => _hoverContent = true),
              onExit:  (_) => setState(() => _hoverContent = false),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: clickable ? (_) => setState(() => _pressedContent = true) : null,
                onTapCancel: clickable ? () => setState(() => _pressedContent = false) : null,
                onTapUp: clickable
                    ? (_) {
                  setState(() => _pressedContent = false);
                  widget.onTap?.call();
                }
                    : null,
                child: SizedBox.expand(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    curve: Curves.easeOut,
                    color: contentBg,
                    padding: EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // 헤더 위젯(아이콘/텍스트)을 본문처럼 왼쪽에 그대로 배치
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: header,
                          ),
                        ),
                        if (chevron != null) ...[
                          Gaps.w4,
                          chevron,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          handle,
        ],
      ),
    );
  }
}
