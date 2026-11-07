import 'package:cartridge/ui/buttons.dart';
import 'package:cartridge/ui/pressable.dart';
import 'package:cartridge/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.autovalidateMode,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.mono = false,
    this.prefix,
    this.suffix,
    this.textAlign = TextAlign.start,
    this.style,
    this.error,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool mono;
  final Widget? prefix;
  final Widget? suffix;
  final TextAlign textAlign;
  final TextStyle? style;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final textStyle = (mono ? AppTextStyles.value : AppTextStyles.body)
        .copyWith(color: enabled ? c.ink : c.ink3)
        .merge(style);

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    const affixConstraints =
        BoxConstraints(minWidth: 28, minHeight: appControlHeight - 2);

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      focusNode: focusNode,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      onTap: onTap,
      validator: validator,
      autovalidateMode: autovalidateMode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      textAlign: textAlign,
      textAlignVertical: TextAlignVertical.center,
      style: textStyle,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        isDense: true,
        constraints: const BoxConstraints(minHeight: appControlHeight),
        filled: true,
        fillColor: c.surface1,
        hintText: placeholder,
        hintStyle: textStyle.copyWith(color: c.ink3),
        errorText: error,
        errorStyle: AppTextStyles.caption.copyWith(color: c.danger),
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        prefixIcon: prefix,
        prefixIconConstraints: affixConstraints,
        suffixIcon: suffix,
        suffixIconConstraints: affixConstraints,
        prefixIconColor: c.ink2,
        suffixIconColor: c.ink2,
        border: border(c.lineStrong),
        enabledBorder: border(c.lineStrong),
        disabledBorder: border(c.line),
        focusedBorder: border(c.accent, 2),
        errorBorder: border(c.danger),
        focusedErrorBorder: border(c.danger, 2),
      ),
    );
  }
}

class AppLabeled extends StatelessWidget {
  const AppLabeled({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, height: 18 / 13)
              .copyWith(color: AppColors.of(context).ink2),
        ),
        child,
      ],
    );
  }
}

class AppNumberField extends StatefulWidget {
  const AppNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min,
    this.max,
    this.placeholder,
    this.showSpinButtons = true,
  });

  final int? value;
  final ValueChanged<int?>? onChanged;
  final int? min;
  final int? max;
  final String? placeholder;
  final bool showSpinButtons;

  @override
  State<AppNumberField> createState() => _AppNumberFieldState();
}

class _AppNumberFieldState extends State<AppNumberField> {
  late final _controller = TextEditingController(text: _format(widget.value));
  late final FocusNode _focusNode = FocusNode()
    ..addListener(() {
      if (!_focusNode.hasFocus) _commit();
    });

  String _format(int? value) => value?.toString() ?? '';

  int? _clamp(int? value) {
    if (value == null) return null;
    if (widget.min != null && value < widget.min!) return widget.min;
    if (widget.max != null && value > widget.max!) return widget.max;
    return value;
  }

  bool _inRange(int value) =>
      (widget.min == null || value >= widget.min!) &&
      (widget.max == null || value <= widget.max!);

  void _onTextChanged(String text) {
    if (text.isEmpty) {
      widget.onChanged?.call(null);
      return;
    }
    final parsed = int.tryParse(text);
    if (parsed != null && _inRange(parsed)) widget.onChanged?.call(parsed);
  }

  void _commit() {
    final next = _clamp(int.tryParse(_controller.text));
    _controller.text = _format(next);
    if (next != widget.value) widget.onChanged?.call(next);
  }

  @override
  void didUpdateWidget(AppNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = _clamp((widget.value ?? widget.min ?? 0) + delta);
    _controller.text = _format(next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;

    return AppTextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: enabled,
      placeholder: widget.placeholder,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))],
      onChanged: _onTextChanged,
      onSubmitted: (_) => _commit(),
      suffix: !widget.showSpinButtons
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIconButton(
                  icon: const PhosphorIcon(PhosphorIconsBold.minus),
                  iconSize: 12,
                  size: 24,
                  onPressed: enabled ? () => _step(-1) : null,
                ),
                AppIconButton(
                  icon: const PhosphorIcon(PhosphorIconsBold.plus),
                  iconSize: 12,
                  size: 24,
                  onPressed: enabled ? () => _step(1) : null,
                ),
                const SizedBox(width: 4),
              ],
            ),
    );
  }
}

class AppSelectItem<T> {
  const AppSelectItem({required this.value, required this.child});

  final T value;
  final Widget child;
}

class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.isExpanded = false,
  });

  final List<AppSelectItem<T>> items;
  final T? value;
  final ValueChanged<T?>? onChanged;
  final Widget? placeholder;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final selectedIndex = items.indexWhere((item) => item.value == value);

    return LayoutBuilder(
      builder: (context, constraints) => MenuAnchor(
        style: MenuStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(isExpanded ? constraints.maxWidth : 160, 0),
          ),
        ),
        alignmentOffset: const Offset(0, 4),
        menuChildren: [
          for (final item in items)
            MenuItemButton(
              onPressed: () => onChanged?.call(item.value),
              style: item.value == value
                  ? ButtonStyle(
                      foregroundColor: WidgetStatePropertyAll(c.accent),
                      textStyle: const WidgetStatePropertyAll(
                          AppTextStyles.bodyStrong),
                    )
                  : null,
              child: item.child,
            ),
        ],
        builder: (context, controller, _) => AppPressable(
          onPressed: onChanged == null || items.isEmpty
              ? null
              : () =>
                  controller.isOpen ? controller.close() : controller.open(),
          builder: (context, states) {
            final disabled = states.contains(WidgetState.disabled);
            final field = Row(
              mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Flexible(
                  fit: isExpanded ? FlexFit.tight : FlexFit.loose,
                  child: DefaultTextStyle.merge(
                    style: AppTextStyles.body
                        .copyWith(color: disabled ? c.ink3 : c.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: IndexedStack(
                      alignment: AlignmentDirectional.centerStart,
                      index: selectedIndex >= 0 ? selectedIndex : items.length,
                      children: [
                        for (final item in items) item.child,
                        DefaultTextStyle.merge(
                          style: TextStyle(color: c.ink3),
                          child: placeholder ?? const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PhosphorIcon(
                  PhosphorIconsBold.caretDown,
                  size: 12,
                  color: disabled ? c.ink3 : c.ink2,
                ),
              ],
            );

            return Container(
              height: appControlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: c.surface1,
                border: Border.all(
                  color: controller.isOpen
                      ? c.accent
                      : (disabled ? c.line : c.lineStrong),
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: field,
            );
          },
        ),
      ),
    );
  }
}
