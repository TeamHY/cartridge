import 'package:cartridge/models/preset.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:cartridge/l10n/app_localizations.dart';

class PresetItem extends StatefulWidget {
  const PresetItem({
    super.key,
    required this.preset,
    required this.onApply,
    required this.onDelete,
    required this.onEdit,
    this.isSelected = false,
    this.onTap,
  });

  final Preset preset;

  final Function(Preset preset) onApply;

  final Function(Preset preset) onDelete;

  final Function(Preset preset) onEdit;

  final bool isSelected;
  final VoidCallback? onTap;

  @override
  State<PresetItem> createState() => _PresetItemState();
}

class _PresetItemState extends State<PresetItem>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.isSelected) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PresetItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else if (!_isHovering) {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = FluentTheme.of(context);

    return Card(
      backgroundColor: widget.isSelected
          ? theme.accentColor.withValues(alpha: 0.1)
          : Colors.transparent,
      borderColor: widget.isSelected ? theme.accentColor : Colors.transparent,
      padding: EdgeInsetsGeometry.zero,
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _isHovering = true);
          _animationController.forward();
        },
        onExit: (_) {
          setState(() => _isHovering = false);
          _animationController.reverse();
        },
        child: material.InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.preset.name,
                    style: TextStyle(
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                      color: widget.isSelected ? theme.accentColor : null,
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    final shouldShow = true; //widget.isSelected || _isHovering;
                    final opacity =
                        1.0; //shouldShow ? _fadeAnimation.value : 0.0;

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: opacity,
                          child: IconButton(
                            onPressed: shouldShow
                                ? () => widget.onApply(widget.preset)
                                : null,
                            icon: Icon(
                              FluentIcons.play,
                              size: 18,
                            ),
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return theme.accentColor
                                      .withValues(alpha: 0.1);
                                }
                                return Colors.transparent;
                              }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return theme.accentColor;
                                }
                                return Colors.black;
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Opacity(
                          opacity: opacity,
                          child: IconButton(
                            onPressed: shouldShow
                                ? () => showDialog(
                                      context: context,
                                      builder: (context) {
                                        return ContentDialog(
                                          title: Text(loc.preset_delete_title),
                                          content:
                                              Text(loc.preset_delete_message),
                                          actions: [
                                            Button(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(loc.common_cancel),
                                            ),
                                            FilledButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    WidgetStatePropertyAll<
                                                        Color>(Colors.red.dark),
                                              ),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                widget.onDelete(widget.preset);
                                              },
                                              child: Text(loc.common_delete),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                : null,
                            icon: const Icon(
                              FluentIcons.delete,
                              size: 18,
                            ),
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.hovered)) {
                                  return Colors.red.withValues(alpha: 0.1);
                                }
                                return Colors.transparent;
                              }),
                              foregroundColor:
                                  WidgetStateProperty.resolveWith((states) {
                                return Colors.red.dark;
                              }),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
