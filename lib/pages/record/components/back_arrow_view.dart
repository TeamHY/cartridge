import 'package:fluent_ui/fluent_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class BackArrowView extends StatelessWidget {
  const BackArrowView({super.key, required this.child, this.controlColor = Colors.white, this.backgroundColor});

  final Widget child;

  final Color controlColor;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  iconButtonMode: IconButtonMode.large,
                  icon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: PhosphorIcon(
                      PhosphorIconsBold.arrowLeft,
                      color: controlColor,
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
                    brightness: controlColor == Colors.white ? Brightness.dark : Brightness.light,
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
      ),
    );
  }
}
