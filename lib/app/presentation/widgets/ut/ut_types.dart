import 'package:fluent_ui/fluent_ui.dart';

/// 폭 스펙
abstract class UTWidth {
  const UTWidth();
  factory UTWidth.px(double px) = UTPx;
  factory UTWidth.flex(int flex) = UTFlex;
}
class UTPx extends UTWidth {
  final double px;
  const UTPx(this.px);
}
class UTFlex extends UTWidth {
  final int flex;
  const UTFlex(this.flex);
}

enum RowOverlayMode { none, replace, blend }

/// 컬럼 스펙
class UTColumnSpec {
  final String id;
  final String title;
  final String? tooltip;
  final UTWidth width;
  final bool sortable;
  final bool resizable;
  final double? minPx;
  final double? maxPx;
  final double? hideBelowPx;

  final Widget? header;

  const UTColumnSpec({
    required this.id,
    required this.title,
    required this.width,
    this.tooltip,
    this.sortable = false,
    this.resizable = true,
    this.minPx,
    this.maxPx,
    this.hideBelowPx,
    this.header, 
  });
}

const double kUTLeadingColWidth = 36.0;   // 체크박스 등
const double kUTTrailingColWidth = 40.0;  // more/menu 등
const double kHeaderHCompact = 32;     // compact일 때
const double kHeaderHComfortable = 40; // comfortable, tile 공통(최대)

class UTQuickFilter<T> {
  final String id;                 // 내부키
  final String label;              // 버튼 라벨
  final bool Function(T row) test; // row가 필터 통과하면 true
  const UTQuickFilter({
    required this.id,
    required this.label,
    required this.test,
  });
}

