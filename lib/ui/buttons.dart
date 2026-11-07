import 'package:cartridge/ui/pressable.dart';
import 'package:cartridge/ui/tokens.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.variant = AppButtonVariant.secondary,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  const AppButton.primary({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  }) : variant = AppButtonVariant.primary;

  const AppButton.ghost({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  }) : variant = AppButtonVariant.ghost;

  const AppButton.danger({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  }) : variant = AppButtonVariant.danger;

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final AppButtonVariant variant;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      builder: (context, states) {
        final c = AppColors.of(context);
        final disabled = states.contains(WidgetState.disabled);
        final hovered = states.contains(WidgetState.hovered);

        Color background = hovered ? c.surface3 : Colors.transparent;
        Color border = disabled ? c.line : c.lineStrong;
        Color foreground = disabled ? c.ink3 : c.ink;
        var weight = FontWeight.w500;

        switch (variant) {
          case AppButtonVariant.primary:
            border = Colors.transparent;
            weight = FontWeight.w600;
            if (disabled) {
              background = c.surface3;
            } else {
              background = hovered
                  ? Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.1), c.accent)
                  : c.accent;
              foreground = c.onAccent;
            }
          case AppButtonVariant.secondary:
            break;
          case AppButtonVariant.ghost:
            border = Colors.transparent;
            if (!disabled) foreground = hovered ? c.ink : c.ink2;
          case AppButtonVariant.danger:
            if (!disabled) {
              border = c.danger;
              foreground = c.danger;
              background = hovered ? c.dangerSoft : Colors.transparent;
            }
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: appControlHeight),
            child: Padding(
              padding: padding,
              child: IconTheme.merge(
                data: IconThemeData(color: foreground, size: 16),
                child: DefaultTextStyle.merge(
                  style: AppTextStyles.body
                      .copyWith(color: foreground, fontWeight: weight),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [if (icon != null) icon!, Flexible(child: child)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum AppIconButtonTone { normal, accent, danger }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.tone = AppIconButtonTone.normal,
    this.active = false,
    this.size = appControlHeight,
    this.iconSize = 16,
    this.color,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonTone tone;
  final bool active;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final button = AppPressable(
      onPressed: onPressed,
      semanticLabel: tooltip,
      builder: (context, states) {
        final c = AppColors.of(context);
        final hovered = states.contains(WidgetState.hovered);
        final danger = tone == AppIconButtonTone.danger;

        final Color foreground;
        if (states.contains(WidgetState.disabled)) {
          foreground = c.lineStrong;
        } else if (active || tone == AppIconButtonTone.accent) {
          foreground = c.accent;
        } else if (hovered) {
          foreground = danger ? c.danger : c.ink;
        } else {
          foreground = color ?? c.ink2;
        }

        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hovered
                ? (danger ? c.dangerSoft : c.surface3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: foreground, size: iconSize),
            child: icon,
          ),
        );
      },
    );

    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
