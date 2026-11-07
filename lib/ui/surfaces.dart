import 'dart:async';

import 'package:cartridge/ui/buttons.dart';
import 'package:cartridge/ui/pressable.dart';
import 'package:cartridge/ui/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.constraints = const BoxConstraints(maxWidth: 420),
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: constraints,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: c.shadowDialog,
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    if (title != null)
                      DefaultTextStyle.merge(
                        style: AppTextStyles.section.copyWith(color: c.ink),
                        child: title!,
                      ),
                    if (content != null)
                      Flexible(
                        child: DefaultTextStyle.merge(
                          style: AppTextStyles.body.copyWith(color: c.ink),
                          child: content!,
                        ),
                      ),
                    if (actions != null && actions!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: actions!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  bool dismissWithEsc = true,
}) {
  return showDialog<T>(
    context: context,
    builder: dismissWithEsc
        ? (context) => _EscToClose(child: builder(context))
        : builder,
    barrierDismissible: barrierDismissible,
    barrierColor: AppColors.of(context).scrim,
  );
}

class _EscToClose extends StatefulWidget {
  const _EscToClose({required this.child});

  final Widget child;

  @override
  State<_EscToClose> createState() => _EscToCloseState();
}

class _EscToCloseState extends State<_EscToClose> {
  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }
    Navigator.of(context).maybePop();
    return true;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum AppNoticeSeverity { info, warning, error, success }

class AppNotice extends StatelessWidget {
  const AppNotice({
    super.key,
    this.title,
    this.content,
    this.severity = AppNoticeSeverity.info,
    this.action,
    this.onClose,
  });

  final Widget? title;
  final Widget? content;
  final AppNoticeSeverity severity;
  final Widget? action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (background, color, icon) = switch (severity) {
      AppNoticeSeverity.info => (c.surface3, c.ink2, PhosphorIconsFill.info),
      AppNoticeSeverity.warning => (
          c.surface3,
          c.warn,
          PhosphorIconsFill.warning
        ),
      AppNoticeSeverity.error => (
          c.dangerSoft,
          c.danger,
          PhosphorIconsFill.xCircle
        ),
      AppNoticeSeverity.success => (
          c.successSoft,
          c.success,
          PhosphorIconsFill.checkCircle
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(background, c.surfaceRaised),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DefaultTextStyle.merge(
        style: AppTextStyles.body.copyWith(color: c.ink),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: PhosphorIcon(icon, size: 16, color: color),
            ),
            Expanded(
              child: Wrap(
                spacing: 8,
                children: [
                  if (title != null)
                    DefaultTextStyle.merge(
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      child: title!,
                    ),
                  if (content != null) content!,
                ],
              ),
            ),
            if (action != null) action!,
            if (onClose != null)
              AppIconButton(
                icon: const PhosphorIcon(PhosphorIconsBold.x),
                iconSize: 12,
                size: 20,
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}

void showAppNotice(
  BuildContext context, {
  required Widget Function(BuildContext context, VoidCallback close) builder,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  Timer? timer;
  var closed = false;

  void close() {
    if (closed) return;
    closed = true;
    timer?.cancel();
    entry.remove();
  }

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 24,
      right: 24,
      bottom: 24,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: AppColors.of(context).shadowMenu,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: builder(context, close),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  timer = Timer(duration, close);
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface1,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: child,
    );
  }
}

class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.onPressed,
    this.selected = false,
    this.leading,
    this.subtitle,
    this.trailing,
  });

  final Widget title;
  final VoidCallback? onPressed;
  final bool selected;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      builder: (context, states) {
        final c = AppColors.of(context);

        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          decoration: BoxDecoration(
            color: selected
                ? c.accentSoft
                : (states.contains(WidgetState.hovered)
                    ? c.surface3
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            spacing: 8,
            children: [
              if (leading != null) leading!,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DefaultTextStyle.merge(
                      style: (selected
                              ? AppTextStyles.bodyStrong
                              : AppTextStyles.body)
                          .copyWith(color: selected ? c.accent : c.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: title,
                    ),
                    if (subtitle != null)
                      DefaultTextStyle.merge(
                        style: AppTextStyles.caption.copyWith(color: c.ink3),
                        child: subtitle!,
                      ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        );
      },
    );
  }
}
