import 'package:cartridge/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class BackArrowView extends StatelessWidget {
  const BackArrowView({
    super.key,
    required this.child,
    this.controlColor = Colors.white,
    this.backgroundColor,
  });

  final Widget child;

  final Color controlColor;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) {
      return Container(color: backgroundColor, child: child);
    }

    return Container(
      color: backgroundColor ?? AppColors.of(context).bg,
      child: Column(
        children: [
          Row(
            children: [
              AppPressable(
                onPressed: () => Navigator.pop(context),
                builder: (context, states) => Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: states.contains(WidgetState.hovered)
                        ? controlColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: PhosphorIcon(
                    PhosphorIconsBold.arrowLeft,
                    color: controlColor,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: DragToMoveArea(
                  child: Container(
                    height: 50,
                  ),
                ),
              ),
              SizedBox(
                width: 138,
                height: 50,
                child: WindowCaption(
                  brightness: controlColor.computeLuminance() > 0.5
                      ? Brightness.dark
                      : Brightness.light,
                  backgroundColor: Colors.transparent,
                ),
              )
            ],
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}
