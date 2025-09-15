import 'package:fluent_ui/fluent_ui.dart';

/// 밀도/뷰 프리셋
///
/// - comfortable : 표 높이 40(기존)
/// - compact     : 표 높이 32(기존)
/// - tile        : 타일 높이 56
enum UTTableDensity { comfortable, compact, tile }

/// UT Table 전용 테마 토큰
class UTTableThemeData {
  // paddings
  final double headerHPadding;
  final double cellHPadding;

  // focus
  final double focusBarWidth;

  // hover/press/selected 강도 (lerp 비율)
  final double hoverLerpLight;
  final double hoverLerpDark;
  final double pressLerpLight;
  final double pressLerpDark;

  // zebra(줄무늬) 강도
  final bool zebraEnabled;
  final double zebraLerpLight;
  final double zebraLerpDark;

  // 헤더 배경 오버라이드(없으면 scaffoldBackgroundColor)
  final Color? headerBackgroundOverride;

  // 헤더 정렬 아이콘
  final Color? headerSortIconColor;        // 중립
  final Color? headerSortIconActiveColor;  // 활성(오름/내림)
  final double headerSortIconSize;

  // 밀도
  final UTTableDensity density;

  const UTTableThemeData({
    // paddings
    this.headerHPadding = 8,
    this.cellHPadding = 8,

    // focus
    this.focusBarWidth = 2,

    // 상태 색 강도(밝음/어둠 테마 별도)
    this.hoverLerpLight = 0.08,
    this.hoverLerpDark  = 0.10,
    this.pressLerpLight = 0.14,
    this.pressLerpDark  = 0.18,

    // zebra
    this.zebraEnabled = false,
    this.zebraLerpLight = 0.08,
    this.zebraLerpDark  = 0.10,

    // header bg
    this.headerBackgroundOverride,

    // header icons
    this.headerSortIconColor,
    this.headerSortIconActiveColor,
    this.headerSortIconSize = 10,

    // density
    this.density = UTTableDensity.comfortable,
  });

  factory UTTableThemeData.fromFluent(
      FluentThemeData t, {
        Color? headerBg,
        UTTableDensity density = UTTableDensity.comfortable,
        bool zebra = false,
      }) {
    final isCompact = density == UTTableDensity.compact;
    return UTTableThemeData(
      headerHPadding: isCompact ? 6 : 8,
      cellHPadding: isCompact ? 6 : 8,
      headerBackgroundOverride: headerBg,
      density: density,
      zebraEnabled: zebra,
    );
  }

  // ── 색 파생 유틸 ───────────────────────────────────────────────────────────
  // base 위에 같은 색을 반투명으로 올리면 변화가 없어 보임 ⇒
  // 밝기 대비용 오버레이(밝은테마: 검정, 어두운테마: 흰색)로 보간해 가시성 확보
  Color _lerpWithContrast(FluentThemeData t, double lightT, double darkT) {
    final base = t.scaffoldBackgroundColor;
    final overlay = t.brightness == Brightness.dark ? Colors.white : Colors.black;
    final tt = t.brightness == Brightness.dark ? darkT : lightT;
    return Color.lerp(base, overlay, tt)!;
  }

  Color rowHoverColor(FluentThemeData t) =>
      _lerpWithContrast(t, hoverLerpLight, hoverLerpDark);

  Color rowPressColor(FluentThemeData t) =>
      _lerpWithContrast(t, pressLerpLight, pressLerpDark);

  Color rowSelectedColor(FluentThemeData t) =>
      (t.brightness == Brightness.dark
          ? t.accentColor.light.withAlpha(30)
          : t.accentColor.normal.withAlpha(24));

  Color zebraColor(FluentThemeData t) =>
      _lerpWithContrast(t, zebraLerpLight, zebraLerpDark);

  Color headerBackground(FluentThemeData t) =>
      headerBackgroundOverride ?? t.scaffoldBackgroundColor;
}

/// Inherited 테마
class UTTableTheme extends InheritedWidget {
  final UTTableThemeData data;
  const UTTableTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static UTTableThemeData of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<UTTableTheme>();
    if (w != null) return w.data;
    return UTTableThemeData.fromFluent(FluentTheme.of(context));
  }

  @override
  bool updateShouldNotify(covariant UTTableTheme oldWidget) =>
      data != oldWidget.data;
}
