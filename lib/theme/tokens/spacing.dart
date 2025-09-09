import 'package:flutter/widgets.dart';

/// 여백/간격/크기 관련 디자인 토큰.
/// - 숫자 하드코딩 대신 모두 여기서 가져가세요.
/// - 공용 SizedBox/EdgeInsets 헬퍼도 함께 제공합니다.
class AppSpacing {
  // 기본 간격 스케일 (dp)
  static const double xxs = 2;
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// 레이아웃 기본 가터(페이지 패딩 등)
  static const double gutter = 16;

  /// Fluent NavigationPane open width.
  static const double navigationPaneSize = 200;

  /// AppBar, Caption 등 공용 높이
  static const double appBarHeight = 50;

  // ---- EdgeInsets 헬퍼 ----
  static EdgeInsets all(double v) => EdgeInsets.all(v);
  static EdgeInsets sym({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);
  static EdgeInsets only({
    double left = 0, double top = 0, double right = 0, double bottom = 0,
  }) => EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
}

/// 자주 쓰는 공용 Gap 위젯들 (가로/세로)
class Gaps {
  // width
  static const w4  = SizedBox(width: AppSpacing.xs);
  static const w8  = SizedBox(width: AppSpacing.sm);
  static const w12 = SizedBox(width: AppSpacing.md);
  static const w16 = SizedBox(width: AppSpacing.lg);
  static const w24 = SizedBox(width: AppSpacing.xl);
  static const w32 = SizedBox(width: AppSpacing.xxl);

  // height
  static const h4  = SizedBox(height: AppSpacing.xs);
  static const h8  = SizedBox(height: AppSpacing.sm);
  static const h12 = SizedBox(height: AppSpacing.md);
  static const h16 = SizedBox(height: AppSpacing.lg);
  static const h24 = SizedBox(height: AppSpacing.xl);
  static const h32 = SizedBox(height: AppSpacing.xxl);
}
