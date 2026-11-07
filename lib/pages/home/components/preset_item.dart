import 'package:cartridge/models/preset.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:cartridge/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
    final c = AppColors.of(context);

    return AppPressable(
      onPressed: widget.onTap,
      focusRadius: 4,
      builder: (context, states) => Container(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? c.accentSoft
              : (states.contains(WidgetState.hovered)
                  ? c.surface3
                  : Colors.transparent),
          border: Border.all(
            color: widget.isSelected ? c.accent : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.preset.name,
                  style: TextStyle(
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                    color: widget.isSelected ? c.accent : null,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconButton(
                        onPressed: () => widget.onApply(widget.preset),
                        icon: const PhosphorIcon(
                          PhosphorIconsRegular.play,
                          size: 16,
                        ),
                      ),
                      AppIconButton(
                        onPressed: () => showAppDialog(
                          context: context,
                          builder: (context) {
                            return AppDialog(
                              constraints: const BoxConstraints(maxWidth: 368),
                              title: Text(loc.preset_delete_title),
                              content: Text(loc.preset_delete_message),
                              actions: [
                                AppButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(loc.common_cancel),
                                ),
                                AppButton.danger(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onDelete(widget.preset);
                                  },
                                  child: Text(loc.common_delete),
                                ),
                              ],
                            );
                          },
                        ),
                        icon: const PhosphorIcon(
                          PhosphorIconsRegular.trash,
                          size: 16,
                        ),
                        tone: AppIconButtonTone.danger,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
