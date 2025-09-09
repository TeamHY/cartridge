import 'package:flutter/widgets.dart';
import '../tokens/breakpoints.dart';

extension BreakpointContext on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  SizeClass get sizeClass => sizeClassFor(screenWidth);

  bool widthUp(double min) => screenWidth >= min;
  bool widthDown(double max) => screenWidth < max;

  bool get isXsUp => widthUp(AppBreakpoints.xs);
  bool get isSmUp => widthUp(AppBreakpoints.sm);
  bool get isMdUp => widthUp(AppBreakpoints.md);
  bool get isLgUp => widthUp(AppBreakpoints.lg);
  bool get isXlUp => widthUp(AppBreakpoints.xl);
}
