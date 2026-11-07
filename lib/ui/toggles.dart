import 'package:cartridge/ui/pressable.dart';
import 'package:cartridge/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Widget _withContent(Widget control, Widget? content, Color color) {
  if (content == null) return control;
  return Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: [
      control,
      Flexible(
        child: DefaultTextStyle.merge(
          style: AppTextStyles.body.copyWith(color: color),
          child: content,
        ),
      ),
    ],
  );
}

class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.content,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? content;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      semanticLabel: semanticLabel,
      focusRadius: 10,
      builder: (context, states) {
        final c = AppColors.of(context);
        final disabled = states.contains(WidgetState.disabled);
        final hovered = states.contains(WidgetState.hovered);

        final track = AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 36,
          height: 20,
          decoration: BoxDecoration(
            color: value ? (disabled ? c.line : c.enabled) : Colors.transparent,
            border: Border.all(
              color: value
                  ? (disabled ? c.line : c.enabled)
                  : (disabled ? c.line : (hovered ? c.ink2 : c.lineStrong)),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 120),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: value
                    ? c.onAccent
                    : (disabled ? c.line : (hovered ? c.ink2 : c.ink3)),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );

        return _withContent(track, content, disabled ? c.ink3 : c.ink);
      },
    );
  }
}

class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.content,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!(value ?? false)),
      focusRadius: AppRadius.sm,
      builder: (context, states) {
        final c = AppColors.of(context);
        final disabled = states.contains(WidgetState.disabled);
        final checked = value != false;

        final box = Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: checked
                ? (disabled ? c.line : c.accent)
                : (states.contains(WidgetState.hovered)
                    ? c.surface3
                    : Colors.transparent),
            border: Border.all(
              color: checked
                  ? (disabled ? c.line : c.accent)
                  : (disabled ? c.line : c.lineStrong),
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: checked
              ? PhosphorIcon(
                  value == null
                      ? PhosphorIconsBold.minus
                      : PhosphorIconsBold.check,
                  size: 12,
                  color: c.onAccent,
                )
              : null,
        );

        return _withContent(box, content, disabled ? c.ink3 : c.ink);
      },
    );
  }
}

class AppRadio extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.checked,
    required this.onChanged,
    this.content,
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onChanged == null ? null : () => onChanged!(true),
      focusRadius: 9,
      builder: (context, states) {
        final c = AppColors.of(context);
        final disabled = states.contains(WidgetState.disabled);

        final circle = Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: disabled ? c.line : (checked ? c.accent : c.lineStrong),
              width: checked ? 5 : 1,
            ),
          ),
        );

        return _withContent(circle, content, disabled ? c.ink3 : c.ink);
      },
    );
  }
}

class AppToggleButton extends StatelessWidget {
  const AppToggleButton({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  final bool checked;
  final ValueChanged<bool>? onChanged;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!checked),
      builder: (context, states) {
        final c = AppColors.of(context);
        final disabled = states.contains(WidgetState.disabled);
        final hovered = states.contains(WidgetState.hovered);

        final foreground = disabled ? c.ink3 : (checked ? c.accent : c.ink);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: checked
                ? c.accentSoft
                : (hovered ? c.surface3 : Colors.transparent),
            border: Border.all(
              color:
                  checked ? c.enabledLine : (disabled ? c.line : c.lineStrong),
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: appControlHeight),
            child: Padding(
              padding: padding,
              child: IconTheme.merge(
                data: IconThemeData(color: foreground, size: 16),
                child: DefaultTextStyle.merge(
                  style: AppTextStyles.body.copyWith(
                    color: foreground,
                    fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Flexible(child: child)],
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

class AppSegment<T> {
  const AppSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final Widget? icon;
}

class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final List<AppSegment<T>> segments;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surface3,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final segment in segments)
            AppPressable(
              onPressed:
                  onChanged == null ? null : () => onChanged!(segment.value),
              semanticLabel: segment.label,
              focusRadius: AppRadius.sm,
              builder: (context, states) {
                final on = segment.value == value;
                final foreground =
                    on || states.contains(WidgetState.hovered) ? c.ink : c.ink2;

                return Container(
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? c.surfaceRaised : Colors.transparent,
                    border: Border.all(
                      color: on ? c.line : Colors.transparent,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground, size: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        if (segment.icon != null) segment.icon!,
                        if (segment.icon == null)
                          Text(
                            segment.label,
                            style: TextStyle(
                              fontSize: 13,
                              height: 18 / 13,
                              color: foreground,
                              fontWeight:
                                  on ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
