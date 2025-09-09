class AppBreakpoints {
  static const double xs = 420;
  static const double sm = 580;
  static const double md = 740;
  static const double lg = 900;
  static const double xl = 1080;
}

enum SizeClass { xxs, xs, sm, md, lg, xl }

SizeClass sizeClassFor(double width) {
  if (width >= AppBreakpoints.xl) return SizeClass.xl;
  if (width >= AppBreakpoints.lg) return SizeClass.lg;
  if (width >= AppBreakpoints.md) return SizeClass.md;
  if (width >= AppBreakpoints.sm) return SizeClass.sm;
  if (width >= AppBreakpoints.xs) return SizeClass.xs;
  return SizeClass.xxs;
}
