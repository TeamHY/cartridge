import 'dart:async';
import 'package:cartridge/features/cartridge/instances/presentation/widgets/instance_image/instance_image_thumb.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/gestures.dart';

import 'package:cartridge/features/cartridge/instances/domain/models/instance_image.dart';

class EditableImageThumb extends StatefulWidget {
  const EditableImageThumb({
    super.key,
    required this.tooltip,
    required this.image,
    required this.seed,
    required this.size,
    required this.radius,
    required this.onTap,
  });

  final String tooltip;
  final InstanceImage? image;
  final String seed;
  final double size;
  final double radius;
  final VoidCallback onTap;

  @override
  State<EditableImageThumb> createState() => _EditableImageThumbState();
}

class _EditableImageThumbState extends State<EditableImageThumb> {
  bool _hovered = false;
  bool _pressed = false;
  Timer? _leaveDebounce;

  @override
  void dispose() {
    _leaveDebounce?.cancel();
    super.dispose();
  }

  void _onEnter(PointerEnterEvent _) {
    _leaveDebounce?.cancel();
    if (!_hovered) setState(() => _hovered = true);
  }

  void _onExit(PointerExitEvent _) {
    _leaveDebounce?.cancel();
    _leaveDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      setState(() {
        _hovered = false;
        _pressed = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final fTheme = FluentTheme.of(context);
    final br = BorderRadius.circular(widget.radius);

    return SizedBox(
      width: widget.size + 2,
      height: widget.size + 2,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: _onEnter,
        onExit: _onExit,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 베이스 이미지 레이어(깜박임 방지)
              const RepaintBoundary(
                child: SizedBox.shrink(),
              ),
              RepaintBoundary(
                child: InstanceImageThumb(
                  image: widget.image,
                  fallbackSeed: widget.seed,
                  size: widget.size,
                  borderRadius: br,
                ),
              ),
              // 오버레이
              IgnorePointer(
                ignoring: !_hovered,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: _hovered ? 1.0 : 0.0,
                  child: Tooltip(
                    message: widget.tooltip,
                    useMousePosition: false,
                    style: const TooltipThemeData(
                      waitDuration: Duration(milliseconds: 200),
                    ),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 90),
                      scale: _pressed ? 0.96 : 1.0,
                      curve: Curves.easeOut,
                      child: Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          borderRadius: br,
                          color: fTheme.accentColor.light.withAlpha(210),
                        ),
                        child: const Center(
                          child: Icon(
                            FluentIcons.edit_photo,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
