import 'package:cartridge/components/app_icon.dart';
import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';

class NavRailItem {
  const NavRailItem({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final AppIcons icon;
  final String label;
  final VoidCallback onPressed;
  final bool selected;
}

class NavRail extends StatelessWidget {
  const NavRail({super.key, required this.items, this.footer});

  final List<NavRailItem> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                spacing: 4,
                children: [
                  for (final item in items) _NavRailButton(item: item)
                ],
              ),
            ),
          ),
          if (footer != null)
            Padding(padding: const EdgeInsets.all(8), child: footer),
        ],
      ),
    );
  }
}

Offset besideRailTarget(TooltipPositionContext context) => Offset(
      context.target.dx + context.targetSize.width / 2 + 8,
      context.target.dy - context.tooltipSize.height / 2,
    );

class _NavRailButton extends StatelessWidget {
  const _NavRailButton({required this.item});

  final NavRailItem item;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      positionDelegate: besideRailTarget,
      child: AppPressable(
        onPressed: item.onPressed,
        semanticLabel: item.label,
        builder: (context, states) {
          final c = AppColors.of(context);

          return Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.selected
                  ? c.accentSoft
                  : (states.contains(WidgetState.hovered)
                      ? c.surface3
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: AppIcon(
              item.icon,
              size: 20,
              color: item.selected ? c.accent : c.ink2,
            ),
          );
        },
      ),
    );
  }
}
