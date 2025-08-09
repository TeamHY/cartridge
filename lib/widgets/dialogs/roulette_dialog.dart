import 'dart:math';

import 'package:cartridge/models/preset.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:roulette/roulette.dart';
import 'package:cartridge/l10n/app_localizations.dart';

class Arrow extends StatelessWidget {
  const Arrow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 36,
      child: CustomPaint(painter: _ArrowPainter()),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  final _paint = Paint()
    ..color = Colors.orange.light
    ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(0, 0)
      ..relativeLineTo(size.width / 2, size.height)
      ..relativeLineTo(size.width / 2, -size.height)
      ..close();
    canvas.drawPath(path, _paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RouletteDialog extends StatefulWidget {
  const RouletteDialog(
      {super.key, required this.presets, required this.onApply});

  final List<Preset> presets;
  final Function(Preset preset) onApply;

  @override
  State<RouletteDialog> createState() => _RouletteDialogState();
}

class _RouletteDialogState extends State<RouletteDialog>
    with TickerProviderStateMixin {
  final Random random = Random();

  late RouletteController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();

    controller = RouletteController(
      group: RouletteGroup.uniform(
        widget.presets.length,
        colorBuilder: (index) => Colors.blue.lightest,
        textBuilder: (index) => widget.presets[index].name,
        textStyleBuilder: (index) => const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Pretendard',
        ),
      ),
      vsync: this,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ContentDialog(
      title: Text(loc.roulette_dialog_title),
      content: Stack(alignment: Alignment.topCenter, children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Roulette(
            controller: controller,
            style: const RouletteStyle(
              centerStickSizePercent: 0,
            ),
          ),
        ),
        const Arrow()
      ]),
      actions: [
        Button(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(loc.common_cancel),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              index = random.nextInt(widget.presets.length);
            });

            controller.rollTo(index, offset: random.nextDouble()).then(
                  (value) => showDialog(
                    context: context,
                    builder: (context) => ContentDialog(
                      title: Text(widget.presets[index].name),
                      content: Text(loc.roulette_result_confirm),
                      actions: [
                        Button(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(loc.common_cancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            widget.onApply(widget.presets[index]);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text(loc.common_apply),
                        ),
                      ],
                    ),
                  ),
                );
          },
          child: Text(loc.roulette_start_button),
        )
      ],
    );
  }
}
