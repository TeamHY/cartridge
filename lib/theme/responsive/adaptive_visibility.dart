import 'package:flutter/widgets.dart';

class AdaptiveVisibility extends StatelessWidget {
  final double? minWidth;
  final double? maxWidth;
  final Widget child;

  const AdaptiveVisibility({super.key, this.minWidth, this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final visible = (minWidth == null || w >= minWidth!) && (maxWidth == null || w < maxWidth!);
    return visible ? child : const SizedBox.shrink();
  }
}
