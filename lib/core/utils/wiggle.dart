import 'dart:math' as math;
import 'package:fluent_ui/fluent_ui.dart';

class Wiggle extends StatefulWidget {
  const Wiggle({
    super.key,
    required this.child,
    required this.enabled,
    this.period = const Duration(milliseconds: 300),
    this.amplitude = 0.00001, // ≈ 0.4°
    this.phaseSeed = 0.0,   // 0..2π 권장
  });

  final Widget child;
  final bool enabled;
  final Duration period;
  final double amplitude;
  final double phaseSeed;

  @override
  State<Wiggle> createState() => _WiggleState();
}

class _WiggleState extends State<Wiggle> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late double _phase;

  @override
  void initState() {
    super.initState();
    _phase = (widget.phaseSeed % (2 * math.pi));
    _ctrl = AnimationController(vsync: this, duration: widget.period);
    if (widget.enabled) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Wiggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.period != widget.period) {
      _ctrl.duration = widget.period;
      if (widget.enabled && !_ctrl.isAnimating) {
        _ctrl.repeat();
      }
    }

    if (oldWidget.enabled != widget.enabled) {
      if (widget.enabled) {
        if (!_ctrl.isAnimating) _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (_, child) {
        // 0..1 → sin 파형 → -amp..+amp
        final angle = math.sin(_ctrl.value * 2 * math.pi + _phase) * widget.amplitude;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateZ(angle),
          child: child,
        );
      },
    );
  }
}
