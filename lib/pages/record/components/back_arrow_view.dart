import 'package:fluent_ui/fluent_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

class BackArrowView extends StatelessWidget {
  const BackArrowView({super.key, required this.child, this.color});

  final Widget child;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: Container(
        color: color,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  iconButtonMode: IconButtonMode.large,
                  icon: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: PhosphorIcon(
                      PhosphorIconsBold.arrowLeft,
                      color: Colors.white,
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
                const SizedBox(
                  width: 138,
                  height: 50,
                  child: WindowCaption(
                    brightness: Brightness.dark,
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
