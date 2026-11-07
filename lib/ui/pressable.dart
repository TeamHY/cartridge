import 'package:cartridge/ui/tokens.dart';
import 'package:flutter/material.dart';

typedef PressableBuilder = Widget Function(
    BuildContext context, Set<WidgetState> states);

class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.onSecondaryTapUp,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.focusRadius = AppRadius.md,
  });

  final VoidCallback? onPressed;
  final GestureTapUpCallback? onSecondaryTapUp;
  final PressableBuilder builder;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;
  final double focusRadius;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (enabled && _hovered) WidgetState.hovered,
      if (enabled && _focused) WidgetState.focused,
      if (enabled && _pressed) WidgetState.pressed,
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          onSecondaryTapUp: widget.onSecondaryTapUp,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          child: Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              widget.builder(context, states),
              if (states.contains(WidgetState.focused))
                Positioned(
                  left: -3,
                  top: -3,
                  right: -3,
                  bottom: -3,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.of(context).accent,
                          width: 2,
                        ),
                        borderRadius:
                            BorderRadius.circular(widget.focusRadius + 3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
