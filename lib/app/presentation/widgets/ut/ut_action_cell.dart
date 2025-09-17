import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;

class UTActionCell extends StatefulWidget {
  const UTActionCell({
    super.key,
    required this.child,
    this.onTap,
    this.tooltip,
    this.showHoverIcon = true,
    this.hoverIcon = material.Icons.open_in_new,
    this.iconSize = 14,
    this.iconPaddingRight = 16, // 아이콘이 겹치는 영역만큼 오른쪽 패딩
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  // 옵션
  final bool showHoverIcon;
  final IconData hoverIcon;
  final double iconSize;
  final double iconPaddingRight;

  @override
  State<UTActionCell> createState() => _UTActionCellState();
}

class _UTActionCellState extends State<UTActionCell> {
  bool _hover = false;
  bool _focused = false;

  bool get _isActionable => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);

    // 텍스트(혹은 child)를 “수축 가능 + 클립” 처리
    final textPart = DefaultTextStyle.merge(
      style: TextStyle(
        decoration: _isActionable && _hover ? TextDecoration.underline : TextDecoration.none,
        fontWeight: FontWeight.w600,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: widget.child, // Text는 호출부에서 overflow: ellipsis, softWrap:false 권장
        ),
      ),
    );

    // 오버레이 아이콘 (레이아웃 폭을 늘리지 않음)
    final overlayIcon = Positioned(
      right: 0,
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          opacity: (_isActionable && widget.showHoverIcon && _hover) ? 0.7 : 0.0,
          duration: const Duration(milliseconds: 120),
          child: Icon(
            widget.hoverIcon,
            size: widget.iconSize,
            color: fTheme.typography.body?.color?.withAlpha(150),
          ),
        ),
      ),
    );

    // 아이콘이 겹칠 공간만 내부에서 패딩으로 비워줌(폭 증가 없음)
    final stack = Stack(
      alignment: Alignment.centerLeft,
      children: [
        Padding(
          padding: EdgeInsets.only(
            right: (_isActionable && widget.showHoverIcon) ? widget.iconPaddingRight : 0,
          ),
          child: textPart,
        ),
        if (_isActionable && widget.showHoverIcon) overlayIcon,
      ],
    );

    final clipped = ClipRect(child: stack);

    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _isActionable ? widget.onTap : null,
      child: MouseRegion(
        cursor: _isActionable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: clipped,
      ),
    );

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
          if (_isActionable) widget.onTap!();
          return null;
        }),
      },
      child: Semantics(
        link: _isActionable,
        button: _isActionable,
        focused: _focused,
        child: widget.tooltip == null ? body : Tooltip(message: widget.tooltip!, child: body),
      ),
    );
  }
}
