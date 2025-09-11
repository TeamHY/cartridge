import 'package:flutter/widgets.dart';

/// 반지름 토큰 (디자인 시스템 공통)
class AppRadius {
  static const double none = 0;
  static const double xs   = 4;
  static const double sm   = 6;
  static const double md   = 8;
  static const double lg   = 12;
  static const double xl   = 16;
}

/// 의미 기반 모양 프리셋
class AppShapes {
  static final BorderRadius card   = BorderRadius.circular(AppRadius.md);
  static final BorderRadius panel  = BorderRadius.circular(AppRadius.lg);
  static final BorderRadius dialog = BorderRadius.circular(AppRadius.lg);
  static final BorderRadius chip   = BorderRadius.circular(AppRadius.sm);
}
