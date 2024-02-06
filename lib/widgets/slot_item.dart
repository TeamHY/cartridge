import 'package:flutter/widgets.dart';

class SlotItem extends StatelessWidget {
  const SlotItem({
    super.key,
    required this.width,
    required this.height,
    required this.text,
  });

  final double width;
  final double height;
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
